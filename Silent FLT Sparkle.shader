Shader "Okano/Silent FLT Sparkle"
{
	Properties
	{
		_MainTex("MainTex", 2D) = "white" {}
		_Color("Color", Color) = (1,1,1,1)
		_ColorMask("ColorMask", 2D) = "black" {}
		_Shadow("Shadow", Range(0, 1)) = 0.4
        _Fresnel ("Fresnel Power", Range(0, 100)) = 20
        _LightingRamp ("Lighting Ramp", 2D) = "white" {}
		_outline_width("outline_width", Float) = 0.2
		_outline_color("outline_color", Color) = (0.5,0.5,0.5,1)
		_outline_tint("outline_tint", Range(0, 1)) = 0.5
        _SpecularMap ("Specular Map", 2D) = "black" {}
        _SpecularPower ("Specular Power", Range(0, 100)) = 20.0
		_BumpMap("BumpMap", 2D) = "bump" {}
		_Cutoff("Alpha cutoff", Range(0,1)) = 0.5
		_EmissionMap ("Emission Map", 2D) = "black" {}
		_Emission ("Emission", Range(0, 10)) = 0
		_EmissionNoiseSizeCoeff("Emission Noise Size Coeff", Range(0,1)) = 0.61
		_EmissionNoiseDensity("Emission Noise Density", float) = -0.61
		_EmissionSparkleSpeed("Emission Sparkle Speed", float) = 10
		_EmissionGreyShift("Emission Grey Shift", Range(0,1)) = 0.5

		// Blending state
		[HideInInspector] _Mode ("__mode", Float) = 0.0
		[HideInInspector] _OutlineMode("__outline_mode", Float) = 0.0
		[HideInInspector] _SrcBlend ("__src", Float) = 1.0
		[HideInInspector] _DstBlend ("__dst", Float) = 0.0
		[HideInInspector] _ZWrite ("__zw", Float) = 1.0
	}

	SubShader
	{
		Tags
		{
			"RenderType" = "Opaque"
		}

		Pass
		{

			Name "FORWARD"
			Tags { "LightMode" = "ForwardBase" }

			Blend [_SrcBlend] [_DstBlend]
			ZWrite [_ZWrite]

			CGPROGRAM
			#include "Libraries/SilentFlatLitToonCore.cginc"
			#include "Libraries/Sparkle.cginc"
			#pragma shader_feature NO_OUTLINE TINTED_OUTLINE COLORED_OUTLINE
			#pragma shader_feature _ _ALPHATEST_ON _ALPHABLEND_ON _ALPHAPREMULTIPLY_ON
			#pragma vertex vert
			#pragma geometry geom
			#pragma fragment frag

			#pragma multi_compile_fwdbase
			#pragma multi_compile_fog

			float4 frag(VertexOutput i) : COLOR
			{
				float4 objPos = mul(unity_ObjectToWorld, float4(0,0,0,1));
				i.normalDir = normalize(i.normalDir);
				float3x3 tangentTransform = float3x3(i.tangentDir, i.bitangentDir, i.normalDir);
				float3 _BumpMap_var = UnpackNormal(tex2D(_BumpMap,TRANSFORM_TEX(i.uv0, _BumpMap)));
				float3 normalDirection = normalize(mul(_BumpMap_var.rgb, tangentTransform)); // Perturbed normals
				float4 _MainTex_var = tex2D(_MainTex,TRANSFORM_TEX(i.uv0, _MainTex));
				
				float3 lightDirection = normalize(_WorldSpaceLightPos0.xyz);
				float3 lightColor = _LightColor0.rgb;
				UNITY_LIGHT_ATTENUATION(attenuation, i, i.posWorld.xyz);
				
                float3 viewDirection = normalize(_WorldSpaceCameraPos.xyz - i.posWorld.xyz);

				fixed4 emissionMap = tex2D(_EmissionMap, i.uv0);
				fixed4 emissive = EffectProcMain(i.uv0, float4(emissionMap.rgb, 1));

				float4 _ColorMask_var = tex2D(_ColorMask,TRANSFORM_TEX(i.uv0, _ColorMask));
				float4 baseColor = lerp((_MainTex_var.rgba*_Color.rgba),_MainTex_var.rgba,_ColorMask_var.r);
				baseColor *= float4(i.col.rgb, 1);

                float4 _SpecularMap_var = tex2D(_SpecularMap,TRANSFORM_TEX(i.uv0, _SpecularMap));
                float3 specular = (_SpecularMap_var.rgb);

				#if COLORED_OUTLINE
				if(i.is_outline) 
				{
					baseColor.rgb = i.col.rgb; 
				}
				#endif

				#if defined(_ALPHATEST_ON)
        		//float mask = saturate(interleaved_gradient(i.pos.xy)+_Cutoff);
        		//float mask = saturate(interleaved_gradient(i.pos.xy)*(_Cutoff*2));f
        		float mask = _Cutoff;
        		clip (baseColor.a - mask);
        		//clip (baseColor.a - _Cutoff);
    			#endif
				
				float3 lightmap = float4(1.0,1.0,1.0,1.0);
				#ifdef LIGHTMAP_ON
				lightmap = DecodeLightmap(UNITY_SAMPLE_TEX2D(unity_Lightmap, i.uv1 * unity_LightmapST.xy + unity_LightmapST.zw));
				#endif

				float3 reflectionMap = DecodeHDR(UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, normalize((_WorldSpaceCameraPos - objPos.rgb)), 7), unity_SpecCube0_HDR)* 0.02;

				float grayscalelightcolor = dot(_LightColor0.rgb, grayscale_vector);
				float bottomIndirectLighting = grayscaleSH9(float3(0.0, -1.0, 0.0));
				float topIndirectLighting = grayscaleSH9(float3(0.0, 1.0, 0.0));
				float grayscaleDirectLighting = dot(lightDirection, normalDirection)*grayscalelightcolor*attenuation + grayscaleSH9(normalDirection);

				float grayscaleDirectLightingSpecular = dot(viewDirection, normalDirection)*grayscalelightcolor*attenuation + grayscaleSH9(normalDirection);

				// Fresnel
				float normalDotEye = dot(normalDirection, viewDirection);
				float fresnelEffect = (pow(1.0-max(0,normalDotEye),_Fresnel));

				float lightDifference = topIndirectLighting + grayscalelightcolor - bottomIndirectLighting;
				float remappedLight = (grayscaleDirectLighting - bottomIndirectLighting) / lightDifference;
				float remappedLightSpecular = (grayscaleDirectLightingSpecular - bottomIndirectLighting) / lightDifference;

				float3 indirectLighting = ((ShadeSH9(half4(0.0, -1.0, 0.0, 1.0)) + reflectionMap));
				float3 directLighting = ((ShadeSH9(half4(0.0, 1.0, 0.0, 1.0)) + reflectionMap + _LightColor0.rgb));

				// MMDs add fresnel through sphere textures, so this isn't that unusual. 
				// It also works better than running it through the lightramp.
				indirectLighting *= 1+fresnelEffect;
				directLighting *= 1+fresnelEffect;

				//float3 directContribution = saturate((1.0 - _Shadow) + floor(saturate(remappedLight) * 2.0));
				//float3 finalColor = emissive + (baseColor * lerp(indirectLighting, directLighting, directContribution));

				remappedLight = mad(remappedLight,(1.0-_Shadow), _Shadow);
				float3 directContribution = tex2D(_LightingRamp, saturate(float2( remappedLight, 0.0)) );
				directContribution = baseColor * lerp(indirectLighting, directLighting, directContribution);

				remappedLightSpecular = pow(remappedLightSpecular, _SpecularPower)+fresnelEffect;
				float3 specularContribution = tex2D(_LightingRamp, saturate(float2( remappedLightSpecular, 0.0)) );
				//specularContribution = specular.rgb*lerp(indirectLighting, directLighting, specularContribution);
				specularContribution = specular.rgb*indirectLighting*specularContribution;

                float3 finalColor = emissive + directContribution + specularContribution;

				fixed4 finalRGBA = fixed4(finalColor * lightmap, baseColor.a);
				UNITY_APPLY_FOG(i.fogCoord, finalRGBA);
				return finalRGBA;
			}
			ENDCG
		}

		Pass
		{
			Name "FORWARD_DELTA"
			Tags { "LightMode" = "ForwardAdd" }
			Blend [_SrcBlend] One

			CGPROGRAM
			#pragma shader_feature NO_OUTLINE TINTED_OUTLINE COLORED_OUTLINE
			#pragma shader_feature _ _ALPHATEST_ON _ALPHABLEND_ON _ALPHAPREMULTIPLY_ON
			#include "Libraries/SilentFlatLitToonCore.cginc"
			#pragma vertex vert
			#pragma geometry geom
			#pragma fragment frag

			#pragma multi_compile_fwdadd_fullshadows
			#pragma multi_compile_fog

			float4 frag(VertexOutput i) : COLOR
			{
				float4 objPos = mul(unity_ObjectToWorld, float4(0,0,0,1));
				i.normalDir = normalize(i.normalDir);
				float3x3 tangentTransform = float3x3(i.tangentDir, i.bitangentDir, i.normalDir);
				float3 _BumpMap_var = UnpackNormal(tex2D(_BumpMap,TRANSFORM_TEX(i.uv0, _BumpMap)));
				float3 normalDirection = normalize(mul(_BumpMap_var.rgb, tangentTransform)); // Perturbed normals
				float4 _MainTex_var = tex2D(_MainTex,TRANSFORM_TEX(i.uv0, _MainTex));

				float3 lightDirection = normalize(_WorldSpaceLightPos0.xyz);
				float3 lightColor = _LightColor0.rgb;
				UNITY_LIGHT_ATTENUATION(attenuation, i, i.posWorld.xyz);
	
				float4 _ColorMask_var = tex2D(_ColorMask,TRANSFORM_TEX(i.uv0, _ColorMask));
				float4 baseColor = lerp((_MainTex_var.rgba*_Color.rgba),_MainTex_var.rgba,_ColorMask_var.r);
				baseColor *= float4(i.col.rgb, 1);

				#if COLORED_OUTLINE
				if(i.is_outline) {
					baseColor.rgb = i.col.rgb;
				}
				#endif

				#if defined(_ALPHATEST_ON)
        		clip (baseColor.a - interleaved_gradient(i.pos.xy));
    			#endif

				float lightContribution = dot(normalize(_WorldSpaceLightPos0.xyz - i.posWorld.xyz),normalDirection)*attenuation;
				float3 directContribution = floor(saturate(lightContribution) * 2.0);
				float3 finalColor = baseColor * lerp(0, _LightColor0.rgb, saturate(directContribution + ((1 - _Shadow) * attenuation)));
				fixed4 finalRGBA = fixed4(finalColor,1) * i.col;
				UNITY_APPLY_FOG(i.fogCoord, finalRGBA);
				return finalRGBA;
			}
			ENDCG
		}

		Pass
		{
			Name "SHADOW_CASTER"
			Tags{ "LightMode" = "ShadowCaster" }

			ZWrite On ZTest LEqual

			CGPROGRAM
			#pragma shader_feature _ _ALPHATEST_ON _ALPHABLEND_ON _ALPHAPREMULTIPLY_ON
			#include "Libraries/FlatLitToonShadows.cginc"
			
			#pragma multi_compile_shadowcaster

			#pragma vertex vertShadowCaster
			#pragma fragment fragShadowCaster
			ENDCG
		}
	}
	FallBack "CubedParadox/Flat Lit Toon (Silent)"
	FallBack "Diffuse"
	CustomEditor "OkanoFlatLitToonSSparkleInspector"
}