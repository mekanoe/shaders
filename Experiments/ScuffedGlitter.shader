Shader "Hidden/Okano/Experiments/Scuffed Glitter" {
	Properties {
		_MainTex ("Main Texture", 2D) = "white"
		_NoiseMap ("Noise Map", 2D) = "white"
	}
	SubShader {
		Tags { "RenderType"="Opaque" }
		LOD 200
		
		CGPROGRAM
		#pragma surface surf Standard addshadow
		#pragma target 4.0

		sampler2D _MainTex;
		sampler2D _NoiseMap;
		fixed _EmissionFloor = 0.98;

		struct Input {
			float2 uv_MainTex;
			float2 uv_NoiseMap;
			float4 light : COLOR;
			float3 screenPos;
			float3 worldPos;
		};

		void surf (Input IN, inout SurfaceOutputStandard o) {
			float3 light = max(float3(0.1, 0.1, 0.15), _LightColor0.rgb);
			float4 c = tex2D(_MainTex, IN.uv_MainTex);

			float4 n = tex2D(_NoiseMap, reflect(IN.screenPos, UnityStereoTransformScreenSpaceTex(IN.uv_NoiseMap)));
    		float3 noiseGreyShifted = min((n + 2) / 3.0 + 0.5, light) * 0.85;
			
			//o.Albedo = saturate(dot(max(0.1, dot(saturate(dot(c * light, IN.screenPos)), n)), c);
			o.Albedo = dot(dot(c * Luminance(n), noiseGreyShifted), light) * c;
			o.Albedo = min(float4(0.9, 0.9, 0.9, 1), o.Albedo);
			// o.Albedo = max(float4(0.1, 0.1, 0.15, 1) * c, o.Albedo);
			if (Luminance(n) > 0.998) {
				o.Emission = dot(dot(c, light), reflect(IN.screenPos, IN.worldPos) * n);
			}

			// o.Normal = saturate(dot(n, reflect(IN.screenPos, IN.worldPos)));

			// o.Albedo = IN.light;
		}
		ENDCG
	}
	FallBack "Diffuse"
}
