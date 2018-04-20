Shader "Okano/Corrupted"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_UVNoiseFloor ("Selection Floor", Range(0,1)) = 0.9
		_Gain ("Gain", float) = 5
		_Random ("Random", float) = 5
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100
		Cull off
		// ZWrite off
		// Blend Zero One

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			// make fog work
			#pragma multi_compile_fog
			
			#include "UnityCG.cginc"
			#include "SimplexNoise.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
			    float4 tangent : TANGENT;
				float2 uv : TEXCOORD0;
				float4 normal : NORMAL;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				UNITY_FOG_COORDS(1)
				float4 vertex : SV_POSITION;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			float _UVNoiseFloor;
			float _Gain;
			float _Random;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				float3 tan = UnityObjectToWorldDir(v.tangent.xyz);

				// move the vert, only if selection noise value is above some value
				float selNoise = snoise(float3(v.uv, _Random)); // deterministic, but not based on unity's UVs
				
				// move it on a sine curve * grow noise value
				if (selNoise >= _UVNoiseFloor) {
					float gain = (1.0 - _UVNoiseFloor) * _Gain;
					float3 movementDir = v.normal.xyz;
					float amount = max(0,(sin(_Time.y) + 1) * 0.5) * gain;

					o.vertex.xyz -= movementDir * amount;
				}
				
				UNITY_TRANSFER_FOG(o,o.vertex);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				// sample the texture
				fixed4 col = tex2D(_MainTex, i.uv);
				// apply fog
				UNITY_APPLY_FOG(i.fogCoord, col);
				return col;
			}
			ENDCG
		}
	}
}
