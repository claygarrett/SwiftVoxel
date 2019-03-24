
# SwiftVoxel
**SwiftVoxel**, as you might have guessed, is a voxel engine written entirely in Swift. It's a side project I embarked on in order to better understand the low-level parts of the render pipeline and also learn about the unique voxel. Check out the [project overview post on Medium](https://medium.com/@claygarrett/grokvox-building-a-voxel-engine-in-100-days-b2c88f687e9d). 

## Voxel Optimizations
![](https://miro.medium.com/fit/c/1400/420/1*Si5UlYcQGay6nOfcsnAUnA.png)
SwiftVoxel using the process of chunking to optimize away the inside faces of grouped voxels, drastically speeding up render times. I wrote more about [Chunking and Instancing here](https://medium.com/@claygarrett/voxel-performance-instancing-vs-chunking-9643d776c11d). 

## Rendering
SwiftVoxel uses Metal 2.0 as its rendering pipeline. Currently, it is implemented using Forward Rendering, but I'm working on a deferred pipeline setup. 

    
