# # Inverse Lighting Tutorial
#
# In this tutorial we shall explore the inverse lighting problem.
# Here, we shall try to reconstruct a target image by optimizing
# the parameters of the light source (using gradients).
# From https://github.com/avik-pal/RayTracer.jl/ by Avik Pal

using RayTracer, Images, Zygote, Flux, Statistics, Random

# ## Configuring the Scene
#
# Reduce the screen_size if the optimization is taking a bit long
screen_size = (w = 180, h = 180)

scene = load_obj("./tree.obj")

# Let us set up the [`Camera`](@ref). For a more detailed understanding of
# the rendering process look into [Introduction to rendering using RayTracer.jl](@ref).
cam = Camera(
    lookfrom = Vec3(0.0f0, 6.0f0, -10.0f0),
    lookat   = Vec3(0.0f0, 2.0f0,  0.0f0),
    vup      = Vec3(0.0f0, 1.0f0,  0.0f0),
    vfov     = 45.0f0,
    focus    = 0.5f0,
    width    = screen_size.w,
    height   = screen_size.h
)

origin, direction = get_primary_rays(cam)

# We should define a few convenience functions. Since we are going to calculate
# the gradients only wrt to `light` we have it as an argument to the function. Having
# `scene` as an additional parameters simply allows us to test our method for other
# meshes without having to run `Zygote.refresh()` repeatedly.
function render(light, scene)
    packed_image = raytrace(origin, direction, scene, light, origin, 2)
    array_image = reshape(hcat(packed_image.x, packed_image.y, packed_image.z),
                          (screen_size.w, screen_size.h, 3, 1))
    return array_image
end

showimg(img) = colorview(RGB, permutedims(zeroonenorm(img)[:,:,:,1], (3,2,1)))

# ## [Ground Truth Image](@id inv_light)
#
# For this tutorial we shall use the [`PointLight`](@ref) source.
# We define the ground truth lighting source and the rendered image. We
# will later assume that we have no information about this lighting
# condition and try to reconstruct the image.
target_light = PointLight(
    color     = Vec3(1.0f0, 1.0f0, 1.0f0),
    intensity = 20000.0f0,
    position  = Vec3(1.0f0, 10.0f0, -50.0f0)
)

target_img = render(target_light, scene)

# The presence of [`zeroonenorm`](@ref) is very important here. It rescales the
# values in the image to 0 to 1. If we don't perform this step `Images` will
# clamp the values while generating the image in RGB format.
showimg(target_img)

# ## Initial Guess of Lighting Parameters
#
# We shall make some arbitrary guess of the lighting parameters (intensity and
# position) and try to get back the image in [Ground Truth Image](@ref inv_light)
light_guess = PointLight(
    color     = Vec3(1.0f0, 1.0f0, 1.0f0),
    intensity = 1.0f0,
    position  = Vec3(-1.0f0, -10.0f0, -50.0f0)
)

showimg(render(light_guess, scene))

# We shall store the images in `results_inv_lighting` directory
mkpath("results_inv_lighting")

save("./results_inv_lighting/inv_light_original.png",
     showimg(render(target_light, scene)))
save("./results_inv_lighting/inv_light_initial.png",
     showimg(render(light_guess, scene)))

# loss function - sum of squares of differences between render and target
function loss_fn(lighting)
    loss = sum((render(lighting, scene) .- target_img) .^ 2)
    @show loss
    return loss
end

# ## Optimization Loop
#
# We will use the ADAM optimizer from Flux. (Try experimenting with other
# optimizers as well). We can also use frameworks like Optim.jl for optimization.
# We will show how to do it in a future tutorial
opt = ADAM(1.5)

@time for i in 1:296
    g = gradient(loss_fn, light_guess)
    update!(opt, light_guess.intensity, g[1].intensity)
    update!(opt, light_guess.position, g[1].position)
    if i % 5 == 1
        save("./results_inv_lighting/iteration_$i.png",
             showimg(render(light_guess, scene)))
    end
end
