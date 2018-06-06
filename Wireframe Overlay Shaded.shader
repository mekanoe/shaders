Shader "Okano/Wireframe Overlay/Diffuse Shaded"
{
    Properties
    {
        _MainTex ("MainTex", 2D) = "white" {}
        _BaseColor ("Base Color", Color) = (0.0, 0.0, 0.0, 0.0)
        _WireframeDrawDistance ("Fade Distance", float) = 1.7
        _Rainbow ("Wireframe Texture", 2D) = "white" {}
        _Speed ("Wireframe Texture Speed", Float ) = 0.1
        _WireThickness ("Wire Thickness", RANGE(0, 800)) = 300
        _WireSmoothness ("Wire Intensity", RANGE(0, 20)) = 20
        _MaxTriSize ("Max Tri Size", RANGE(0, 200)) = 25
    }

    SubShader
    {
        Tags {
            "RenderType"="Opaque"
        }

        Pass
        {
            Cull False

            CGPROGRAM
            #pragma geometry geom
            #pragma fragment frag
            #pragma vertex vert
            #define NW_SHADED 1
            #include "UnityCG.cginc"
            #include "Libraries/Wireframe.cginc"
            ENDCG
        }
        Pass {
            Name "ShadowCaster"
            Tags {
                "LightMode"="ShadowCaster"
            }
            Offset 1, 1
            Cull Off
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #define UNITY_PASS_SHADOWCASTER
            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #pragma fragmentoption ARB_precision_hint_fastest
            #pragma multi_compile_shadowcaster
            #pragma only_renderers d3d9 d3d11 glcore gles 
            #pragma target 3.0
            struct VertexInput {
                float4 vertex : POSITION;
            };
            struct VertexOutput {
                V2F_SHADOW_CASTER;
            };
            VertexOutput vert (VertexInput v) {
                VertexOutput o = (VertexOutput)0;
                o.pos = UnityObjectToClipPos( v.vertex );
                TRANSFER_SHADOW_CASTER(o)
                return o;
            }
            float4 frag(VertexOutput i, float facing : VFACE) : COLOR {
                float isFrontFace = ( facing >= 0 ? 1 : 0 );
                float faceSign = ( facing >= 0 ? 1 : -1 );
                SHADOW_CASTER_FRAGMENT(i)
            }
            ENDCG
        }
    }
}
