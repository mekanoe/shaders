// Wireframe shader based on the the following
// http://developer.download.nvidia.com/SDK/10/direct3d/Source/SolidWireframe/Doc/SolidWireframe.pdf

// Shaded doesn't need certain features on, especially since it doesn't include a main texture.
#ifndef NW_SHADED
#define NW_SHADED 0
#endif

#pragma fragment frag
#include "UnityCG.cginc"
#pragma fragmentoption ARB_precision_hint_fastest
#pragma multi_compile_shadowcaster
#pragma only_renderers d3d9 d3d11 glcore gles 
#pragma target 4.0

uniform float _WireThickness = 100;
uniform float _WireSmoothness = 20;
uniform float4 _WireColor = float4(0.0, 1.0, 0.0, 1.0);
uniform float4 _BaseColor = float4(0.0, 0.0, 0.0, 0.0);
uniform float _MaxTriSize = 25.0;
uniform float _WireframeDrawDistance = 3.0;
uniform sampler2D _MainTex; uniform float4 _MainTex_ST;
uniform sampler2D _Rainbow; uniform float4 _Rainbow_ST;
uniform float _Speed;//

struct appdata
{
    float4 vertex : POSITION;
    float2 texcoord0 : TEXCOORD0;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct VertexInput {
    float4 vertex : POSITION;
    float3 normal : NORMAL;
    float2 texcoord0 : TEXCOORD0;
    float2 texcoord1 : TEXCOORD1;
    float2 texcoord2 : TEXCOORD2;
};

struct VertexOutput {
    float4 pos : SV_POSITION;
    float2 uv0 : TEXCOORD0;
    float2 uv1 : TEXCOORD1;
    float2 uv2 : TEXCOORD2;
};

struct v2g
{
    float4 projectionSpaceVertex : SV_POSITION;
    float2 uv0 : TEXCOORD0;
    float4 worldSpacePosition : TEXCOORD1;
    UNITY_VERTEX_OUTPUT_STEREO
};

struct g2f
{
    float4 projectionSpaceVertex : SV_POSITION;
    float2 uv0 : TEXCOORD0;
    float4 worldSpacePosition : TEXCOORD1;
    float4 dist : TEXCOORD2;
    float4 area : TEXCOORD3;
    UNITY_VERTEX_OUTPUT_STEREO
};

v2g vert (appdata v)
{
    v2g o = (v2g)0;
    o.uv0 = float2(0,0);
    // o.dist = float2(0,0);
    // o.area = float2(0,0);
    UNITY_SETUP_INSTANCE_ID(v);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
    o.projectionSpaceVertex = UnityObjectToClipPos(v.vertex);
    o.worldSpacePosition = mul(unity_ObjectToWorld, v.vertex);
    #if NW_SHADED == 1
    o.uv0 = TRANSFORM_TEX(v.texcoord0, _MainTex);
    #endif
    return o;
}

[maxvertexcount(3)]
void geom(triangle v2g i[3], inout TriangleStream<g2f> triangleStream)
{
    float2 p0 = i[0].projectionSpaceVertex.xy / i[0].projectionSpaceVertex.w;
    float2 p1 = i[1].projectionSpaceVertex.xy / i[1].projectionSpaceVertex.w;
    float2 p2 = i[2].projectionSpaceVertex.xy / i[2].projectionSpaceVertex.w;

    float2 edge0 = p2 - p1;
    float2 edge1 = p2 - p0;
    float2 edge2 = p1 - p0;

    float4 worldEdge0 = i[0].worldSpacePosition - i[1].worldSpacePosition;
    float4 worldEdge1 = i[1].worldSpacePosition - i[2].worldSpacePosition;
    float4 worldEdge2 = i[0].worldSpacePosition - i[2].worldSpacePosition;

    // To find the distance to the opposite edge, we take the
    // formula for finding the area of a triangle Area = Base/2 * Height, 
    // and solve for the Height = (Area * 2)/Base.
    // We can get the area of a triangle by taking its cross product
    // divided by 2.  However we can avoid dividing our area/base by 2
    // since our cross product will already be double our area.
    float area = abs(edge1.x * edge2.y - edge1.y * edge2.x);
    float wireThickness = 800 - _WireThickness;

    g2f o;

    o.area = float4(0, 0, 0, 0);
    o.area.x = max(length(worldEdge0), max(length(worldEdge1), length(worldEdge2)));
    
    o.uv0 = i[0].uv0;
    o.worldSpacePosition = i[0].worldSpacePosition;
    o.projectionSpaceVertex = i[0].projectionSpaceVertex;
    o.dist.xyz = float3( (area / length(edge0)), 0.0, 0.0) * o.projectionSpaceVertex.w * wireThickness;
    o.dist.w = 1.0 / o.projectionSpaceVertex.w;
    UNITY_TRANSFER_VERTEX_OUTPUT_STEREO(i[0], o);
    triangleStream.Append(o);

    o.uv0 = i[1].uv0;
    o.worldSpacePosition = i[1].worldSpacePosition;
    o.projectionSpaceVertex = i[1].projectionSpaceVertex;
    o.dist.xyz = float3(0.0, (area / length(edge1)), 0.0) * o.projectionSpaceVertex.w * wireThickness;
    o.dist.w = 1.0 / o.projectionSpaceVertex.w;
    UNITY_TRANSFER_VERTEX_OUTPUT_STEREO(i[1], o);
    triangleStream.Append(o);

    o.uv0 = i[2].uv0;
    o.worldSpacePosition = i[2].worldSpacePosition;
    o.projectionSpaceVertex = i[2].projectionSpaceVertex;
    o.dist.xyz = float3(0.0, 0.0, (area / length(edge2))) * o.projectionSpaceVertex.w * wireThickness;
    o.dist.w = 1.0 / o.projectionSpaceVertex.w;
    UNITY_TRANSFER_VERTEX_OUTPUT_STEREO(i[2], o);
    triangleStream.Append(o);
}

float4 frag(g2f i, float facing : VFACE) : SV_Target {

    float minDistanceToEdge = min(i.dist[0], min(i.dist[1], i.dist[2])) * i.dist[3];

    #if NW_SHADED == 1
    float4 baseColor = _BaseColor * tex2D(_MainTex, i.uv0);    
    #else
    float4 baseColor = _BaseColor; 
    #endif

    // Early out if we know we are not on a line segment.
    if(minDistanceToEdge > 0.9)
    {
        return fixed4(baseColor.rgb,1);
    }

    // Smooth our line out
    float t = exp2((20 - _WireSmoothness) * -1.0 * minDistanceToEdge * minDistanceToEdge);
    // remove lines after some distance
    float4 objPos = mul(unity_ObjectToWorld, float4(0,0,0,1));
    float4 distance = abs(objPos - float4(_WorldSpaceCameraPos, 1));
    float maxDist = max(distance.x, max(distance.y, distance.z)); 
    float ddSq = _WireframeDrawDistance * 2;

    // if beyond draw distance *2, just skip
    if(maxDist > (ddSq)) {
        return fixed4(baseColor.rgb, 1);      
    }
    // if beyond draw distance, scale smoothness up some
    if(maxDist > _WireframeDrawDistance) {
        t = min(t, 1.0 - maxDist/ddSq);
    }

    // Smooth our line out
    float isFrontFace = ( facing >= 0 ? 1 : 0 );
    float faceSign = ( facing >= 0 ? 1 : -1 );
    float4 time = _Time;
    float2 timeUV0 = (i.dist+(_Speed*time.g));
    float4 _Rainbow_var = tex2D(_Rainbow,TRANSFORM_TEX(timeUV0, _Rainbow));

    
    float4 finalColor = float4(lerp(baseColor, _Rainbow_var.rgb, t), 1);
    
    return finalColor;
}