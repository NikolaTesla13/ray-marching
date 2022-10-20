@group(0) @binding(0) var output_texture: texture_storage_2d<rgba8unorm, write>;

struct HitPayload {
    distance: f32,
    albedo: vec3<f32>
};

struct Sphere {
    origin: vec3<f32>,
    radius: f32,
    albedo: vec3<f32>
};

let MAX_MARCHING_STEPS: i32 = 255;
let MIN_DIST: f32 = 0.0;
let MAX_DIST: f32 = 100.0;
let EPSILON: f32 = 0.0001;

fn smooth_max(a: f32, b: f32, k: f32) -> f32 {
    return log(exp(k * a) + exp(k * b)) / k;
}

fn smooth_min(a: f32, b: f32, k: f32) -> f32 {
    return -smooth_max(-a, -b, k);
}

fn sphere_sdf(sample_point: vec3<f32>, sphere: Sphere) -> HitPayload {
    let payload = HitPayload(
        length(sample_point - sphere.origin) - sphere.radius, 
        sphere.albedo
    );
    return payload;
}

fn scene_sdf(sample_point: vec3<f32>) -> HitPayload {
    let s1 = sphere_sdf(sample_point, Sphere(
        vec3<f32>(-1.0, 0.0, 0.0), 
        1.2,
        vec3<f32>(0.2, 0.9, 0.2)
    ));

    let s2 = sphere_sdf(sample_point, Sphere(
        vec3<f32>(1.0, 0.0, 0.0), 
        1.2,
        vec3<f32>(0.9, 0.2, 0.2)
    ));

    let closest = smooth_min(s1.distance, s2.distance, 5.0);

    let interpolation = clamp(0.5 + 0.5 * (s2.distance - s1.distance) / 1.5, 0.0, 1.0);
    let color = mix(s1.albedo, s2.albedo, interpolation);

    return HitPayload(closest, color);
}

fn estimate_normals(p: vec3<f32>) -> vec3<f32> {
    return normalize(vec3<f32>(
        scene_sdf(vec3<f32>(p.x + EPSILON, p.y, p.z)).distance - scene_sdf(vec3<f32>(p.x - EPSILON, p.y, p.z)).distance,
        scene_sdf(vec3<f32>(p.x, p.y + EPSILON, p.z)).distance - scene_sdf(vec3<f32>(p.x, p.y - EPSILON, p.z)).distance,
        scene_sdf(vec3<f32>(p.x, p.y, p.z  + EPSILON)).distance - scene_sdf(vec3<f32>(p.x, p.y, p.z - EPSILON)).distance
    ));
}

fn shortest_distance_to_surface(eye: vec3<f32>, marching_dir: vec3<f32>, start: f32, end: f32) -> HitPayload {
    var depth = start;
    for(var i=0; i<MAX_MARCHING_STEPS; i+=1) {
        let dist = scene_sdf(eye + depth * marching_dir);
        if dist.distance < EPSILON {
            return HitPayload(
                depth, dist.albedo
            );
        }
        depth += dist.distance;
        if depth >= end {
            return HitPayload(end, vec3<f32>(0.0));
        }
    }
    return HitPayload(end, vec3<f32>(0.0));
}

fn ray_direction(fov: f32, size: vec2<f32>, coords: vec2<f32>) -> vec3<f32> {
    let xy = coords - size / 2.0;
    let z = size.y / tan(radians(fov) / 2.0);
    return normalize(vec3<f32>(xy, -z));
}

@compute @workgroup_size(16, 16)
fn compute_main(
        @builtin(global_invocation_id) global_id: vec3<u32>
) {
    let dimensions = vec2<f32>(f32(textureDimensions(output_texture).x), f32(textureDimensions(output_texture).y));
    let coords = vec2<f32>(f32(global_id.x), f32(global_id.y));

    if coords.x >= dimensions.x || coords.y >= dimensions.y {
        return;
    }

    let dir = ray_direction(45.0, dimensions, coords);
    let eye = vec3<f32>(0.0, 0.0, 10.0);
    let dist = shortest_distance_to_surface(eye, dir, MIN_DIST, MAX_DIST);

    if dist.distance > (MAX_DIST - EPSILON) {
        return;
    }

    let light_dir = normalize(vec3<f32>(1.0, 0.8, -1.0));
    let normal = estimate_normals(eye + dist.distance * dir);
    let light_intensity = max(dot(normal, -light_dir), 0.0);

    let result = dist.albedo * light_intensity;

    textureStore(output_texture, vec2<i32>(coords.xy), vec4<f32>(result, 1.0));
}
