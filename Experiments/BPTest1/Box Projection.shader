Shader "Hidden/Okano/Experiments/Box Projection" {
    Properties {
        _RampTex ("Ramp Texture", 2D) = "white" {}
        _FloorColor ("Floor Color", Color) = (0.1,0.1,0.3,1)
        
        [Category(Boxes)]_BoxSize ("Box Size", Float) = 1
        _BoxPadding ("Box Padding", Float) = 0.1

        [Category(Layering)][IntRange]_Layers ("Layers (High Perf Cost)", Range(1,100)) = 3
        _LayerDistance ("Layer Distance", Float) = 0.1
    }
    SubShader {
        Tags { "RenderType"="Opaque" }

        Pass {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog
            
            #include "UnityCG.cginc"

            struct appdata {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                float3 tangent : TANGENT;
            };

            struct v2f {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : POSITION0;
                float3 normal : NORMAL0;
                float3 viewDir : NORMAL1;
                float3 tangent : TANGENT;
            };

            sampler2D _RampTex; float4 _RampTex_ST;
            float4 _FloorColor;
            float _BoxSize;
            float _BoxPadding;
            uint _Layers;
            float _LayerDistance;

            float boxFromUV (float2 uv) {
                float scalarSize = (_BoxSize + _BoxPadding);
                float2 size = float2(scalarSize, scalarSize);

                float2 transUV = float2(fmod(abs(uv.x), scalarSize), fmod(abs(uv.y), scalarSize));
                if (transUV.x <= _BoxPadding / 2 || transUV.y <= _BoxPadding / 2 ) {
                    return 0; // do not draw
                } else {
                    return 1; // do draw
                }
            }

            float2 parallax (float distance, float3 viewPos, float3 normal, float3 tangent) {
                float3 vRefl = dot(-viewPos, normal);
                float3 vTrans = -tangent;
                float fDist = distance;
                return fDist * vTrans.xy;
            }
            
            v2f vert (appdata v) {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                // o.normal = normalize(v.normal);
                o.normal = v.normal;
                o.tangent = v.tangent;
                o.viewDir = ObjSpaceViewDir(v.vertex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }
            
            fixed4 frag (v2f i) : COLOR {
                // sample the texture
                fixed4 col = _FloorColor;

                // run this backwards, building from floor to top
                for (uint n = _Layers; n > 0; n--) {
                    float distance = _LayerDistance * (n);
                    float2 offsetUV = parallax(distance, i.viewDir, i.normal, i.tangent);
                    float res = boxFromUV(i.uv + offsetUV);
                    if (res == 1) {
                        // col = tex2D(_RampTex, TRANSFORM_TEX(float2(offsetUV), _RampTex));
                        col = float4(1,1,1,1);
                    }
                }

                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
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
            #define _GLOSSYENV 1
            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "UnityPBSLighting.cginc"
            #include "UnityStandardBRDF.cginc"	
            #pragma fragmentoption ARB_precision_hint_fastest
            #pragma multi_compile_shadowcaster
            #pragma only_renderers d3d9 d3d11 glcore gles 
            #pragma target 3.0
            struct appdata {
                float4 vertex : POSITION;
            };
            struct v2f {
                V2F_SHADOW_CASTER;
            };

            v2f vert (appdata v) {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                
                // UNITY_TRANSFER_FOG(o,o.vertex);
                // UNITY_TRANSFER_DEPTH(o,o.depth);
                return o;
            }

            float4 frag(v2f i, float facing : VFACE) : COLOR {
                float isFrontFace = ( facing >= 0 ? 1 : 0 );
                float faceSign = ( facing >= 0 ? 1 : -1 );
                SHADOW_CASTER_FRAGMENT(i)
            }
            ENDCG
        }
    }
}
