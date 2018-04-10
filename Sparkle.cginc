struct appdata
{
    float4 vertex : POSITION;
    float2 uv : TEXCOORD0;
};

struct v2f
{
    float2 uv : TEXCOORD0;
    float4 vertex : SV_POSITION;
};

//#####################################

// Updated have more configuration and add photoshop blend modes on existing textures
// Description : Array and textureless GLSL 2D/3D/4D simplex 
//               noise functions.
//      Author : Ian McEwan, Ashima Arts.
//  Maintainer : ijm
//     Lastmod : 20151020 (hassoncs)
//     License : Copyright (C) 2011 Ashima Arts. All rights reserved.
//               Distributed under the MIT License. See LICENSE file.
//               https://github.com/ashima/webgl-noise
// 

uniform float _EmissionNoiseSizeCoeff; // Bigger => larger glitter spots
uniform float _EmissionNoiseDensity;  // Bigger => larger glitter spots
uniform float _EmissionSparkleSpeed;


float3 mod289(float3 x) {
    return x - floor(x * (1.0 / 289.0)) * 289.0;
}

float4 mod289(float4 x) {
    return x - floor(x * (1.0 / 289.0)) * 289.0;
}

float4 permute(float4 x) {
    return mod289(((x*34.0) + 1.0)*x);
}

float4 taylorInvSqrt(float4 r)
{
    return 1.79284291400159 - 0.85373472095314 * r;
}

float snoise(float3 v)
{
    float2  C = float2(1.0 / 6.0, 1.0 / 3.0);//const
    float4  D = float4(0.0, 0.5, 1.0, 2.0);//const

    // First corner
    float3 i = floor(v + dot(v, C.yyy));
    float3 x0 = v - i + dot(i, C.xxx);

    // Other corners
    float3 g = step(x0.yzx, x0.xyz);
    float3 l = 1.0 - g;
    float3 i1 = min(g.xyz, l.zxy);
    float3 i2 = max(g.xyz, l.zxy);

    //   x0 = x0 - 0.0 + 0.0 * C.xxx;
    //   x1 = x0 - i1  + 1.0 * C.xxx;
    //   x2 = x0 - i2  + 2.0 * C.xxx;
    //   x3 = x0 - 1.0 + 3.0 * C.xxx;
    float3 x1 = x0 - i1 + C.xxx;
    float3 x2 = x0 - i2 + C.yyy; // 2.0*C.x = 1/3 = C.y
    float3 x3 = x0 - D.yyy;      // -1.0+3.0*C.x = -0.5 = -D.y

                                // Permutations
    i = mod289(i);
    float4 p = permute(permute(permute(
        i.z + float4(0.0, i1.z, i2.z, 1.0))
        + i.y + float4(0.0, i1.y, i2.y, 1.0))
        + i.x + float4(0.0, i1.x, i2.x, 1.0));

    // Gradients: 7x7 points over a square, mapped onto an octahedron.
    // The ring size 17*17 = 289 is close to a multiple of 49 (49*6 = 294)
    float n_ = 0.142857142857; // 1.0/7.0
    float3  ns = n_ * D.wyz - D.xzx;

    float4 j = p - 49.0 * floor(p * ns.z * ns.z);  //  mod(p,7*7)

    float4 x_ = floor(j * ns.z);
    float4 y_ = floor(j - 7.0 * x_);    // mod(j,N)

    float4 x = x_ *ns.x + ns.yyyy;
    float4 y = y_ *ns.x + ns.yyyy;
    float4 h = 1.0 - abs(x) - abs(y);

    float4 b0 = float4(x.xy, y.xy);
    float4 b1 = float4(x.zw, y.zw);

    float4 s0 = floor(b0)*2.0 + 1.0;
    float4 s1 = floor(b1)*2.0 + 1.0;
    float4 sh = -step(h, float4(0,0,0,0));

    float4 a0 = b0.xzyw + s0.xzyw*sh.xxyy;
    float4 a1 = b1.xzyw + s1.xzyw*sh.zzww;

    float3 p0 = float3(a0.xy, h.x);
    float3 p1 = float3(a0.zw, h.y);
    float3 p2 = float3(a1.xy, h.z);
    float3 p3 = float3(a1.zw, h.w);

    // Normalise gradients
    float4 norm = taylorInvSqrt(float4(dot(p0, p0), dot(p1, p1), dot(p2, p2), dot(p3, p3)));
    p0 *= norm.x;
    p1 *= norm.y;
    p2 *= norm.z;
    p3 *= norm.w;

    // Mix final noise value
    float4 m = max(_EmissionNoiseSizeCoeff - float4(dot(x0, x0), dot(x1, x1), dot(x2, x2), dot(x3, x3)), 0.0);
    m = m * m;
    return _EmissionNoiseDensity * dot(m*m, float4(dot(p0, x0), dot(p1, x1),
        dot(p2, x2), dot(p3, x3)));
}


float softLight(float s, float d)
{
    return (s < 0.5) ? d - (1.0 - 2.0 * s) * d * (1.0 - d)
        : (d < 0.25) ? d + (2.0 * s - 1.0) * d * ((16.0 * d - 12.0) * d + 3.0)
        : d + (2.0 * s - 1.0) * (sqrt(d) - d);
}

float3 softLight(float3 s, float3 d)
{
    float3 c;
    c.x = softLight(s.x, d.x);
    c.y = softLight(s.y, d.y);
    c.z = softLight(s.z, d.z);
    return c;
}

float hardLight(float s, float d)
{
    return (s < 0.5) ? 2.0 * s * d : 1.0 - 2.0 * (1.0 - s) * (1.0 - d);
}

float3 hardLight(float3 s, float3 d)
{
    float3 c;
    c.x = hardLight(s.x, d.x);
    c.y = hardLight(s.y, d.y);
    c.z = hardLight(s.z, d.z);
    return c;
}

float vividLight(float s, float d)
{
    return (s < 0.5) ? 1.0 - (1.0 - d) / (2.0 * s) : d / (2.0 * (1.0 - s));
}

float3 vividLight(float3 s, float3 d)
{
    float3 c;
    c.x = vividLight(s.x, d.x);
    c.y = vividLight(s.y, d.y);
    c.z = vividLight(s.z, d.z);
    return c;
}

float3 linearLight(float3 s, float3 d)
{
    return 2.0 * s + d - 1.0;
}

float pinLight(float s, float d)
{
    return (2.0 * s - 1.0 > d) ? 2.0 * s - 1.0 : (s < 0.5 * d) ? 2.0 * s : d;
}

float3 pinLight(float3 s, float3 d)
{
    float3 c;
    c.x = pinLight(s.x, d.x);
    c.y = pinLight(s.y, d.y);
    c.z = pinLight(s.z, d.z);
    return c;
}



float4 EffectProcMain(in float2 uv, in float4 mainColorUpperLayer)
{
    float fadeLR = 0.5 - abs(uv.x - 0.5);
    float fadeTB = 1.0 - uv.y;

    float2 xyPart = uv * float2(3.0, 1.0) - float2(0.0, _Time[0] * _EmissionSparkleSpeed * 0.00005);
    float zPart = _Time[0] * _EmissionSparkleSpeed * 0.006;
    float3 pos = float3(xyPart, zPart);

    float n = fadeLR * fadeTB * smoothstep(0.50, 1.0, snoise(pos * 80.0)) * 8.0;

    // a bunch of constants here to shift the black-white of the noise to a greyer tone
    float3 noiseGreyShifted = min((float3(n, n, n) + 1.0) / 3.0 + 0.3, float3(1.0, 1.0, 1.0)) * 0.91;


    float3 mixed = mainColorUpperLayer;
    //mixed = softLight(noiseGreyShifted, s);
    //mixed = hardLight(noiseGreyShifted, s);
    mixed = vividLight(noiseGreyShifted, mainColorUpperLayer);
    //mixed = pinLight(noiseGreyShifted, s);
    //mixed = linearLight(noiseGreyShifted, s);

    return float4(mixed, 1.0);
}
