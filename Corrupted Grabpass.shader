Shader "Okano/Corrupted Grabpass"
{
    Properties
    {
        _Tint ("Color", Color) = (0,0,0,0)
        // _MainTex ("Texture", 2D) = "white" {}
        _UVNoiseFloor ("Selection Floor", Range(0,1)) = 0.9
        _Gain ("Gain", float) = 5
        _Random ("Random", float) = 5
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent+10" }
        Cull off
        // ZWrite off
        // Offset -1,-1
        // ZBlend

        GrabPass {							
            Tags { "LightMode" = "Always" }
         }
        

        Pass
        {
            CGPROGRAM
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
                float4 uvgrab : TEXCOORD1;		
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _UVNoiseFloor;
            sampler2D _GrabTexture;
            float _Gain;
            float _Random;
            float4 _Tint;
            
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.uvgrab = ComputeGrabScreenPos(o.vertex);
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
            
            half4 frag (v2f i) : SV_Target
            {
                // fout fo;
                // sample the texture
                half4 col = tex2Dproj( _GrabTexture, UNITY_PROJ_COORD(i.uvgrab));

                // col.rgb = float3(i.amount, i.amount, i.amount) * 100;
                // apply fog
                // UNITY_APPLY_FOG(i.fogCoord, col);
                // fo.color = col * _Tint;
                // fo.depth = -1;
                col.a = _Tint.a;
                return col;
            }
            ENDCG
        }
    }
}
