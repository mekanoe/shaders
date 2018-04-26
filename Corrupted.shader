Shader "Okano/Corrupted"
{
    Properties
    {
        _Tint ("Color", Color) = (0,0,0,0)
        _MainTex ("Texture", 2D) = "white" {}
        _UVNoiseFloor ("Selection Floor", Range(0,1)) = 0.9
        _Gain ("Gain", float) = 5
        _Random ("Random", float) = 5
        [Toggle]_Shadows ("Cast Shadows?", Float) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        Cull off
        // ZWrite off
        // Offset -1,-1
        // ZBlend

        Pass
        {
            CGPROGRAM
// Upgrade NOTE: excluded shader from DX11; has structs without semantics (struct v2f members amount)
// #pragma exclude_renderers d3d11
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog
            
            #include "UnityCG.cginc"
            #include "Libraries/SimplexNoise.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float4 normal : NORMAL;
                // float4 tangent : TANGENT;
                // float2 depth : TEXCOORD1;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                // UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
                float amount : PSIZE0;
            };

            struct fout 
            {
                float4 color:COLOR;
                float depth:DEPTH;
            };     

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _UVNoiseFloor;
            float _Gain;
            float _Random;
            float4 _Tint;
            
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.amount = 0;
                // move the vert, only if selection noise value is above some value
                float selNoise = snoise(float3(v.uv, _Random) + (_Time.x * 3.141592)); // deterministic, but not based on unity's UVs
                // move it on a sine curve * grow noise value
                if (selNoise >= _UVNoiseFloor) {
                    float gain = (1.0 - _UVNoiseFloor) * _Gain;
                    float amount = (max(-0.2,(_SinTime.y + 1) * 0.5)) * gain * selNoise;
                    // float3 tan = UnityObjectToWorldDir(v.tangent.xyz);
                    
                    float3 movementDir = v.normal.xyz;
                    o.vertex.xyz -= (movementDir * amount);
                    o.amount = amount;
                }
                
                // UNITY_TRANSFER_FOG(o,o.vertex);
                // UNITY_TRANSFER_DEPTH(o,o.depth);
                return o;
            }
            
            half4 frag (v2f i) : COLOR
            {
                // sample the texture
                half4 col = tex2D(_MainTex, i.uv);				

                // col.rgb = float3(i.amount, i.amount, i.amount) * 100;
                // apply fog
                // UNITY_APPLY_FOG(i.fogCoord, col);
    
                return col * _Tint;
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
            #include "Libraries/SimplexNoise.cginc"			
            #pragma shader_feature _ _SHADOWS_ON
            #pragma fragmentoption ARB_precision_hint_fastest
            #pragma multi_compile_shadowcaster
            #pragma only_renderers d3d9 d3d11 glcore gles 
            #pragma target 3.0
            float _Random;
            float _UVNoiseFloor;
            float _Gain;
            struct appdata {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float4 normal : NORMAL;
            };
            struct v2f {
                V2F_SHADOW_CASTER;
            };

            v2f vert (appdata v) {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                // move the vert, only if selection noise value is above some value
                float selNoise = snoise(float3(v.uv, _Random) + (_Time.x * 3.141592)); // deterministic, but not based on unity's UVs
                // move it on a sine curve * grow noise value
                if (selNoise >= _UVNoiseFloor) {
                    float gain = (1.0 - _UVNoiseFloor) * _Gain;
                    float amount = (max(-0.2,(_SinTime.y + 1) * 0.5)) * gain * selNoise;
                    // float3 tan = UnityObjectToWorldDir(v.tangent.xyz);
                    
                    float3 movementDir = v.normal.xyz;
                    o.pos.xyz -= (movementDir * amount);
                }
                
                // UNITY_TRANSFER_FOG(o,o.vertex);
                // UNITY_TRANSFER_DEPTH(o,o.depth);
                return o;
            }

            float4 frag(v2f i, float facing : VFACE) : COLOR {
                float isFrontFace = ( facing >= 0 ? 1 : 0 );
                float faceSign = ( facing >= 0 ? 1 : -1 );
                #if defined(_SHADOWS_ON)
                SHADOW_CASTER_FRAGMENT(i)
                #else
                clip(-1);
                return float4(0,0,0,0);
                #endif
            }
            ENDCG
        }
    }
}
