Shader "Hidden/Okano/Experiments/Layering"
{
	Properties
	{
		[Header(Top Plane)]
		_TopPlanarTint ("Top Planar Tint", Color) = (0,1,1,1)
		_TopPlanarTex ("Top Planar Texture", 2D) = "black" {}
		_TopPlanarCutoff ("Top Planar Cutoff", Range(0,1)) = 0.5

		[Header(Bottom Plane)]
		_BottomPlanarTex ("Bottom Planar Texture", 2D) = "white" {}
		_Distance ("Distance", Float) = 0.1
		_FloatDistance ("Float Distance", Float) = 0.5
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			// make fog work
			#pragma multi_compile_fog
			
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				float4 tangent : TANGENT;
				float4 normal : NORMAL;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				UNITY_FOG_COORDS(1)
				float4 vertex : SV_POSITION;
				float3 tangentViewDir : TANGENT0;
				float3 worldViewDir : TANGENT1;
			};

			float4 _TopPlanarTint;
			sampler2D _TopPlanarTex; float4 _TopPlanarTex_ST;
			float _TopPlanarCutoff;
			sampler2D _BottomPlanarTex; float4 _BottomPlanarTex_ST;
			float _Distance;
			float _Speed;
			float _FloatDistance;

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;

				float3 worldVertexPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				float3 worldViewDir = worldVertexPos - _WorldSpaceCameraPos;
				float3 worldNormal = UnityObjectToWorldNormal(v.normal);
				float3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
				float3 worldBitangent = cross(worldNormal, worldTangent) * v.tangent.w * unity_WorldTransformParams.w;

				o.tangentViewDir = float3(
					dot(worldViewDir, worldTangent),
					dot(worldViewDir, worldNormal),
					dot(worldViewDir, worldBitangent)
				);
				o.worldViewDir = worldViewDir;

				UNITY_TRANSFER_FOG(o,o.vertex);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				// sample top tex
				float4 col = tex2D(_TopPlanarTex, TRANSFORM_TEX(i.uv, _TopPlanarTex));
				clip(col.a - _TopPlanarCutoff);
				UNITY_APPLY_FOG(i.fogCoord, col);
				return col;
			}
			ENDCG
		}

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			// make fog work
			#pragma multi_compile_fog
			
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				float4 tangent : TANGENT;
				float4 normal : NORMAL;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				UNITY_FOG_COORDS(1)
				float4 vertex : SV_POSITION;
				float3 tangentViewDir : TANGENT0;
				float3 worldViewDir : TANGENT1;
			};

			float4 _TopPlanarTint;
			sampler2D _TopPlanarTex; float4 _TopPlanarTex_ST;
			float _TopPlanarCutoff;
			sampler2D _BottomPlanarTex; float4 _BottomPlanarTex_ST;
			float _Distance;
			float _Speed;
			float _FloatDistance;

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;

				float3 worldVertexPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				float3 worldViewDir = worldVertexPos - _WorldSpaceCameraPos;
				float3 worldNormal = UnityObjectToWorldNormal(v.normal);
				float3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
				float3 worldBitangent = cross(worldNormal, worldTangent) * v.tangent.w * unity_WorldTransformParams.w;

				o.tangentViewDir = float3(
					dot(worldViewDir, worldTangent),
					dot(worldViewDir, worldNormal),
					dot(worldViewDir, worldBitangent)
				);
				o.worldViewDir = worldViewDir;

				UNITY_TRANSFER_FOG(o,o.vertex);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				// sample top tex
				float4 col = tex2D(_TopPlanarTex, TRANSFORM_TEX(i.uv, _TopPlanarTex));
				clip(col.a - _TopPlanarCutoff);
				UNITY_APPLY_FOG(i.fogCoord, col);
				return col;
			}
			ENDCG
		}
	}
}
