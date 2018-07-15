#if !defined(FLOW_INCLUDED)
#define FLOW_INCLUDED
static const float PI = 3.14159265f;

float2 FlowUV (float2 uv, float2 flowVector, float time) {
    float progress = frac(time);
    return uv - flowVector * progress;
}

float3 FlowUVW(float2 uv, float2 flowVector, float time, bool flowB) {
    float phaseOffset = flowB ? 0.5 : 0;
    float progress = frac(time + phaseOffset);
    float3 uvw;
    uvw.xy = uv - flowVector * progress + phaseOffset;
    //uvw.z = 1;
    uvw.z = 1; //- abs(1 - 2 * progress);
    //uvw.z = 1 - abs(1 - sin(PI * progress));
    //uvw.z = 1 - abs(1 - sin(PI * progress));
    return uvw;
}


#endif