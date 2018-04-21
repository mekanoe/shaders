Shader "Hidden/Okano/Experiments/Deep Fried" {
	Properties {
		_MainTex ("Main Tex" , 2D) = "white" {}
		_MemeMap ("Meme Map" , 2D) = "white" {}
		_NoiseMap ("Noise Map" , 2D) = "white" {}
	}
	SubShader {
		Tags { "RenderType"="Opaque" }
		LOD 200
		Cull off
		
		CGPROGRAM
		// Physically based Standard lighting model, and enable shadows on all light types
		#pragma surface surf Standard fullforwardshadows

		// Use shader model 3.0 target, to get nicer looking lighting
		#pragma target 3.0
		#include "../Libraries/SimplexNoise.cginc"

		sampler2D _MainTex;
		sampler2D _NoiseMap;
		sampler2D _MemeMap;
		fixed3 cyan = fixed3(0,1,1);
		fixed3 yellow = fixed3(1,1,0);

		struct Input {
			float2 uv_MainTex;
			float2 uv_NoiseMap;
			float2 uv_MemeMap;
		};

		void surf (Input IN, inout SurfaceOutputStandard o) {
			// Albedo comes from a texture tinted by color
			float4 c = tex2D(_MainTex, IN.uv_MainTex);
			float4 n = tex2D(_NoiseMap, IN.uv_NoiseMap);
			float4 n2 = tex2D(_MemeMap, IN.uv_MemeMap);

			float r = snoise(c.rgb * n.rgb);
			float r2 = snoise(_Time[0] + (c.rgb * n2.rgb / max(0.01, n.rgb)));
			float r3 = snoise((n2.rgb / max(0.01, n.rgb)));
			float3 a = float3(r,r2,0);
			float3 a2 = dot(a, float3(r2,r2,0));
			float3 alb = saturate(c.rgb + dot(c.rgb * r, a * 2) + (-a2*r3*r2) + (-a*-r2));
			float3 offset = float3(1,0.7,0.2);
			alb *= dot(alb,offset) * offset;
			o.Albedo = alb;
		}
		ENDCG
	}
	FallBack "Diffuse"
}
