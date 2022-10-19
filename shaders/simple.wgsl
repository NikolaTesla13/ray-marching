struct VertexInput {
    @location(0) position: vec3<f32>,
    @location(1) color: vec3<f32>,
    @location(2) tex_coords: vec2<f32>,
};

struct VertexOutput {
    @builtin(position) clip_position: vec4<f32>,
    @location(0) color: vec3<f32>,
    @location(1) tex_coords: vec2<f32>,
};

@group(0) @binding(0) var output_texture: texture_storage_2d<rgba8unorm, write>;
@group(0) @binding(1) var display_texture: texture_2d<f32>;
@group(0) @binding(2) var _sampler: sampler;

@vertex
fn vs_main(
    model: VertexInput,
) -> VertexOutput {
    var out: VertexOutput;
    out.color = model.color;
    out.tex_coords = model.tex_coords;
    out.clip_position = vec4<f32>(model.position * 2.0, 1.0);
    return out;
}

@fragment
fn fs_main(in: VertexOutput) -> @location(0) vec4<f32> {
    let color: vec4<f32> = textureSample(display_texture, _sampler, in.tex_coords);
    let gamma_corrected = pow(color.xyz, vec3<f32>(2.2));

    return vec4<f32>(gamma_corrected, 1.0);
}

@compute @workgroup_size(16, 16)
fn compute_main(
        @builtin(global_invocation_id) global_id: vec3<u32>
) {
    let dimensions = textureDimensions(output_texture);
    let coords = vec2<i32>(global_id.xy);

    if coords.x >= dimensions.x || coords.y >= dimensions.y {
        return;
    }

    let color = vec4<f32>(1.0 - vec2<f32>(coords) / vec2<f32>(dimensions.xy), 0.0, 1.0);

    textureStore(output_texture, coords.xy, color);
}