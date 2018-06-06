Shader "Okano/LUT Rim Lighting"
{
	Properties
	{
		_RimEdgePower("Rim Edge Tightness", Float) = 10
		_RimStartDistance("Rim Start Distance", Float) = 1
		[Toggle(_USERIMCOLOR)] _UseRimColor("Use Rim Color", Float) = 0
		_RimColor("Rim Color", Color) = (0.2,0,0,0)
		_RimRamp ("Rim Ramp (LUT)", 2D) = "black" {}
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		Cull off

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			// make fog work
			#pragma multi_compile_fog
			#pragma shader_feature _USERIMCOLOR
			
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
			};

			struct v2f
			{
				float4 vertex : SV_POSITION;
				float3 viewDir : TEXCOORD0;
				float3 normalDir : TEXCOORD1;
				float3 posWorld : TEXCOORD2;
			};

			float4 _RimColor;
			float _RimEdgePower;
			float _RimStartDistance;
			sampler2D _RimRamp; float4 _RimRamp_ST;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.viewDir = normalize(UnityWorldSpaceViewDir(mul(unity_ObjectToWorld, v.vertex)));
				o.normalDir = UnityObjectToWorldNormal(v.normal);
				o.posWorld = mul(unity_ObjectToWorld, v.vertex);
				
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{	
				half rim = 1.0 - saturate(dot(normalize(i.viewDir), i.normalDir)) * _RimEdgePower;
				
				half rimAmount = 0;
				half distanceFromObject = distance(_WorldSpaceCameraPos.xyz, i.posWorld);
				if (distanceFromObject < _RimStartDistance) {
					rimAmount = (_RimStartDistance - distanceFromObject) / _RimStartDistance;
				}

				float4 rimColor;

				#if defined(_USERIMCOLOR)
				rimColor = rim * _RimColor;
				#else 
				rimColor = tex2D(_RimRamp, float2(rim, rim));
				#endif

				return rimColor * rimAmount + fixed4(0,0,0,1);
			}
			ENDCG
		}
	}
}
