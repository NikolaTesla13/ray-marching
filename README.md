# ray-marching ⚡

This is an implementation of the ray marching algorithm, a rendering technique.

## How it works - TLDR

Ray marching is like a simplified version of ray tracing. Instead of sending rays recursively into the scene and checking for collisions, it uses `signed distance field functions` to iteratively determine the distance to any object in the scene. The ray travels until the minimum distance is smaller than an `epsilon` value, 0.0001, which means we hit an object.

Some uses of it include 3D fractals and creating infinite scenes, not necessarily made out of triangles. Very few games use it.

![example](https://media.discordapp.net/attachments/833285965019217980/1033080399036952606/unknown.png)

## Resources

Here are some of the sources I used to learn this algorithm:

- https://iquilezles.org/articles/distfunctions/
- http://jamie-wong.com/2016/07/15/ray-marching-signed-distance-functions/
- https://www.shadertoy.com/view/Xds3zN
- https://www.shadertoy.com/view/3sySRK

## License

[GPLv3](LICENSE) © [Asandei Stefan](https://www.stefan-asandei.cf)
