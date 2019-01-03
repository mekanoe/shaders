Shader "Okano/HalftoneToon"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_NormalMap ("Normal Map", 2D) = "bump" {}
		_CircleSize ("Grid Frequency", Int) = 1
		_CircleColor ("Circle Color", Color) = (1,1,1,1)
		[Toggle(_USE_ENVIRONMENT_LIGHTING)] _UseEnvLight ("Use Environment Light", Float) = 1
		_Power ("Power", Range(0,1)) = 1
		_RimPower ("Rim Power", Float) = 1
		_RimDotPower ("Rim Dot Power", Float) = 1
		_ToonRamp ("Toon Ramp", 2D) = "white" {}
		_ToonPower ("Toon Power", Range(0,1)) = 0.7
		_DotRanges ("Dot Min/Maxes (Prim XY, Rim ZW)", Vector) = (-0.5,3,-0.5,2)
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100

		Pass
		{
			Tags {
				"LightMode" = "ForwardBase"
			}
			CGPROGRAM

			#pragma vertex vert
			#pragma fragment frag
			// make fog work
			#pragma multi_compile_fog
			
			#include "UnityCG.cginc"
			#include "UnityStandardBRDF.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				float4 normal : NORMAL;
				float4 tangent : TANGENT;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float3 normal : NORMAL;
				float3 tangent : TANGENT;
				UNITY_FOG_COORDS(1)
				float4 worldPos : TEXCOORD2;
				// float4 screenUV : TEXCOORD3;
				float3 bitangent : TEXCOORD3;
				float4 vertex : SV_POSITION;
			};

			sampler2D _MainTex; float4 _MainTex_ST;
			sampler2D _NormalMap; float4 _NormalMap_ST;
			sampler2D _ToonRamp; float4 _ToonRamp_ST;
			int _CircleSize;
			float4 _CircleColor;
			float _Power;
			float _RimPower;
			float _RimDotPower;
			float4 _DotRanges;
			float _ToonPower;

			float4 aastep(float threshold, float value) {
				float afwidth = 0.75 * length(float2(ddx(value), ddy(value)));
				return smoothstep(threshold-afwidth, threshold+afwidth, value);
			}
			
			float4 circleGrid(float2 uv, float size, float lightAmount, float2 mm) {
				float2 uvRotated = mul(float2x2(0.707, -0.707, 0.707, 0.707), uv);
				float2 nearest = 2 * frac( size * uvRotated ) - 1;
				float dist = distance(nearest, 0);
				float radius = pow(lightAmount,_Power*10);
				if (radius < 0.05) {
					return 0;
				}
				// return radius;
				return 1-aastep(max(0,lerp(mm.x, mm.y, radius)), dist-0.05);

			}

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.normal = UnityObjectToWorldNormal(v.normal);
				o.tangent = normalize(mul(unity_ObjectToWorld, float4(v.tangent.xyz, 0.0)).xyz);
				o.bitangent = normalize(cross(o.normal, o.tangent) * v.tangent.w);
				o.worldPos = mul(unity_ObjectToWorld, v.vertex);
				// o.screenUV = ComputeScreenPos(v.vertex);
				UNITY_TRANSFER_FOG(o,o.vertex);
				return o;
			}

			float3 StereoWorldViewDir(float3 worldPos) {
				#if UNITY_SINGLE_PASS_STEREO
				float3 cameraPos = float3((unity_StereoWorldSpaceCameraPos[0]+ unity_StereoWorldSpaceCameraPos[1])*.5); 
				#else
				float3 cameraPos = _WorldSpaceCameraPos;
				#endif
				float3 worldViewDir = normalize((cameraPos - worldPos));
				return worldViewDir;
			}
			
			void calcNormals(inout v2f i, float3 v) {
				i.normal = normalize(i.normal);
                float3x3 TBN = float3x3( i.tangent, i.bitangent, i.normal);
                float3 viewDirection = normalize(v - i.worldPos.xyz);
                float3 normMap = UnpackNormal(tex2D(_NormalMap,TRANSFORM_TEX(i.uv, _NormalMap)));
                i.normal = normalize(mul( normMap, TBN )); // Perturbed normals
			}

			fixed4 frag (v2f i) : SV_Target
			{
				float3 viewDir = StereoWorldViewDir(i.worldPos);
				// calculate normals
				calcNormals(i, viewDir);

				// i.normal = normalize(i.normal);
				float3 lightDir = _WorldSpaceLightPos0.xyz;

				float NdotL = DotClamped(i.normal, lightDir);
				// float NdotLV = DotClamped(i.normal, normalize(lightDir + viewDir));
				float NdotV = 1 - DotClamped(i.normal, viewDir);
				float lighting = NdotL + pow(NdotV, _RimPower*0.3-0.3);
				// return lighting;

				fixed4 cgrid = circleGrid(i.uv, _CircleSize, NdotL, _DotRanges.xy);
				cgrid += circleGrid(i.uv, _CircleSize, pow(NdotV, _RimDotPower), _DotRanges.zw);
				fixed4 tex = tex2D(_MainTex, i.uv);
				fixed4 toon = tex2D(_ToonRamp, lighting.xx * _ToonRamp_ST.xy);
				fixed3 col = saturate((lerp(toon.rgb,1,_ToonPower) * tex)+cgrid);

				// apply fog
				UNITY_APPLY_FOG(i.fogCoord, col);
				return float4(col, 1);
			}
			ENDCG
		}
	}
}
