Shader "Custom/BinstonGlowToon"
{
	Properties
	{
		_Color("Color", Color) = (1,1,1,1)
		_Color2("Color", Color) = (1,1,1,0)
		_Color3("Color", Color) = (1,1,1,0)
		_Color4("Glow Color", Color) = (1,1,1,0)
		_Color5("Outside Glow Color", Color) = (1,1,1,0)
		_MainTex("Albedo", 2D) = "white" {}
		_MainTex2 ("Texture", 2D) = "white" {}
		[Enum(R,0,G,1,B,2)] _OutlineRGB ("Outline RGB", Float) = 2		
		
		_Cutoff("Alpha Cutoff", Range(0.0, 1.0)) = 0.5

		_Glossiness("Smoothness", Range(0.0, 1.0)) = 0.5
		_GlossMapScale("Smoothness Scale", Range(0.0, 1.0)) = 1.0
		[Enum(Metallic Alpha,0,Albedo Alpha,1)] _SmoothnessTextureChannel ("Smoothness texture channel", Float) = 0

		[Gamma] _Metallic("Metallic", Range(0.0, 1.0)) = 0.0
		_MetallicGlossMap("Metallic", 2D) = "white" {}

		[ToggleOff] _SpecularHighlights("Specular Highlights", Float) = 1.0
		[ToggleOff] _GlossyReflections("Glossy Reflections", Float) = 1.0

		_BumpScale("Scale", Float) = 1.0
		_BumpMap("Normal Map", 2D) = "bump" {}

		_Parallax ("Height Scale", Range (0.005, 0.08)) = 0.02
		_ParallaxMap ("Height Map", 2D) = "black" {}

		_OcclusionStrength("Strength", Range(0.0, 1.0)) = 1.0
		_OcclusionMap("Occlusion", 2D) = "white" {}

		_EmissionColor("Color", Color) = (0,0,0)
		_EmissionMap("Emission", 2D) = "white" {}
		
		_DetailMask("Detail Mask", 2D) = "white" {}

		_DetailAlbedoMap("Detail Albedo x2", 2D) = "grey" {}
		_DetailNormalMapScale("Scale", Float) = 1.0
		_DetailNormalMap("Normal Map", 2D) = "bump" {}
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

		[Enum(UV0,0,UV1,1)] _UVSec ("UV Set for secondary textures", Float) = 0

		[Header(Stencil)]
		_Stencil ("Stencil ID [0;255]", Float) = 0
		_ReadMask ("ReadMask [0;255]", Int) = 255
		_WriteMask ("WriteMask [0;255]", Int) = 255
		[Enum(UnityEngine.Rendering.CompareFunction)] _StencilComp ("Stencil Comparison", Int) = 3
		[Enum(UnityEngine.Rendering.StencilOp)] _StencilOp ("Stencil Operation", Int) = 0
		[Enum(UnityEngine.Rendering.StencilOp)] _StencilFail ("Stencil Fail", Int) = 0
		[Enum(UnityEngine.Rendering.StencilOp)] _StencilZFail ("Stencil ZFail", Int) = 0

		// Blending state
		[HideInInspector] _Mode ("__mode", Float) = 0.0
		[HideInInspector] _SrcBlend ("__src", Float) = 1.0
		[HideInInspector] _DstBlend ("__dst", Float) = 0.0
		[HideInInspector] _ZWrite ("__zw", Float) = 1.0
	}

	CGINCLUDE
		#define UNITY_SETUP_BRDF_INPUT MetallicSetup
	ENDCG

	SubShader
	{
		Tags { "RenderType"="Opaque" "PerformanceChecks"="False" }
		LOD 300
	
		Stencil
		{
			Ref [_Stencil]
			ReadMask [_ReadMask]
			WriteMask [_WriteMask]
			Comp [_StencilComp]
			Pass [_StencilOp]
			Fail [_StencilFail]
			ZFail [_StencilZFail]
		}
		// ------------------------------------------------------------------
		//  Base forward pass (directional light, emission, lightmaps, ...)
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
        		clip (baseColor.a - 0.5);
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
			Name "BINSTONGLOW"
			//Blend DstColor SrcColor
			Blend [_SrcBlend] [_DstBlend]
			ZWrite Off
			Cull Off
			Tags
			{
				"RenderType"="Transparent"
				"Queue"="Transparent"
			}
			
						
			CGPROGRAM
			#pragma target 3.0
			#pragma vertex vert
			#pragma fragment frag
			#pragma shader_feature NO_OUTLINE TINTED_OUTLINE COLORED_OUTLINE
			#pragma shader_feature _ _ALPHATEST_ON _ALPHABLEND_ON _ALPHAPREMULTIPLY_ON
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				float3 normal : NORMAL;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float2 screenuv : TEXCOORD1;
				float3 viewDir : TEXCOORD2;
				float3 objectPos : TEXCOORD3;
				float4 vertex : SV_POSITION;
				float depth : DEPTH;
				float3 normal : NORMAL;
			};

			sampler2D _MainTex;
			sampler2D _MainTex2;
			float4 _MainTex_ST;
			float4 _MainTex2_ST;
			int _OutlineRGB;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex2);

				o.screenuv = ((o.vertex.xy / o.vertex.w) + 1)/2;
				o.screenuv.y = 1 - o.screenuv.y;
				o.depth = -mul(UNITY_MATRIX_MV, v.vertex).z *_ProjectionParams.w;

				o.objectPos = v.vertex.xyz;		
				o.normal = UnityObjectToWorldNormal(v.normal);
				o.viewDir = normalize(UnityWorldSpaceViewDir(mul(unity_ObjectToWorld, v.vertex)));

				return o;
			}
			sampler2D _CameraDepthNormalsTexture;
			fixed4 _Color;
			fixed4 _Color2;
			fixed4 _Color3;
			fixed4 _Color4;
			fixed4 _Color5;
			
			float triWave(float t, float offset, float yOffset)
			{
				return saturate(abs(frac(offset + t) * 2 - 1) + yOffset);
			}

			fixed4 texColor(v2f i, float rim, bool phaseShift)
			{
				float3 offset = phaseShift ? 0.5 : 0.0;
				fixed4 mainTex = tex2D(_MainTex2, i.uv);
				if(_OutlineRGB == 0) {
					mainTex.g *= triWave(_Time.x * 5 + offset, abs(i.objectPos.y) * 2, -0.7) * 6;
					// I ended up saturaing the rim calculation because negative values caused weird artifacts
					mainTex.r *= saturate(rim) * (sin(_Time.z + offset + mainTex.r * 5) + 1);
					return mainTex.r * _Color + mainTex.g * _Color;
				}				
				if(_OutlineRGB == 1) {
					mainTex.b *= triWave(_Time.x * 5 + offset, abs(i.objectPos.y) * 2, -0.7) * 6;
					// I ended up saturaing the rim calculation because negative values caused weird artifacts
					mainTex.g *= saturate(rim) * (sin(_Time.z + offset + mainTex.g * 5) + 1);
					return mainTex.b * _Color + mainTex.g * _Color;
				}
				if(_OutlineRGB == 2) {
					mainTex.r *= triWave(_Time.x * 5 + offset, abs(i.objectPos.y) * 2, -0.7) * 6;
					// I ended up saturaing the rim calculation because negative values caused weird artifacts
					mainTex.g *= saturate(rim) * (sin(_Time.z + offset + mainTex.b * 5) + 1);
					return mainTex.r * _Color + mainTex.g * _Color;
				}
				return mainTex.r * _Color + mainTex.g * _Color;
			}		

            float3 VRViewPosition(){
				#if defined(USING_STEREO_MATRICES)
				float3 leftEye = unity_StereoWorldSpaceCameraPos[0];
				float3 rightEye = unity_StereoWorldSpaceCameraPos[1];
				
				float3 centerEye = lerp(leftEye, rightEye, 0.5);
				#endif
				#if !defined(USING_STEREO_MATRICES)
				float3 centerEye = _WorldSpaceCameraPos;
				#endif
				return centerEye;
            }				
			
			fixed4 frag (v2f i) : SV_Target
			{

				float3 VRPosition = VRViewPosition();
                float3 VRWorldCamPosition = (i.posWorld.rgb-VRPosition);
				//Add directional light with minimum intensity to avatar 5 0s and a 1
				float screenDepth = DecodeFloatRG(tex2D(_CameraDepthNormalsTexture, i.screenuv).zw);
				float diff = screenDepth - i.depth;
				float intersect = 0;
				
				//if (diff > 0)
					intersect = 1 - smoothstep(0, _ProjectionParams.w * 0.5, diff);

				// float rim = 1 - abs(dot(i.normal, normalize(i.viewDir))) * 2;
				float rim = 1 - abs(dot(i.normal, normalize(VRWorldCamPosition))) * 2;
				//float northPole = (i.objectPos.y - 0.45) * 20;
				//float glow = max(max(intersect, rim), northPole);
				float glow = max(intersect, rim);

				fixed4 glowColor = fixed4(lerp(_Color4.rgb, _Color5.rgb, pow(glow, 4)), 1);
				
				fixed4 hexes = texColor(i, rim, true) * _Color3;
				fixed4 hexes2 = texColor(i, rim, false) * _Color3;
				float4 mainColor = tex2D(_MainTex, i.uv);
				//fixed4 col = tex2D(_MainTex, i.uv) * _Color * _Color.a + glowColor * glow + hexes;
				float4 col = tex2D(_MainTex, i.uv) * _Color * _Color2.a + glowColor * glow + hexes + hexes2;
				clip(col.a - 0.5);
				fixed4 finalColor = col.rgba;
				return finalColor;
			}
			ENDCG
		}	
	}


	FallBack "VertexLit"
}