Shader "Okano/Simple Lit Toon" {
	Properties {
		_MainTex ("Texture", 2D) = "white" {}
		_ToonRamp ("Toon Ramp", 2D) = "white" {}
		_Emission ("Emission Map", 2D) = "black" {}
		[Normal] _NormalMap ("Normal Map", 2D) = "bump" {}
		_NormalScale ("Normal Scale", Float) = 1
	}
	SubShader {
		Tags { "RenderType"="Opaque" }

		Pass {
			Name "FORWARD"
			Tags { "LightMode" = "ForwardBase" }
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			// make fog work
			#pragma multi_compile_fog
			#pragma multi_compile_fwdbase			
			
			#include "UnityCG.cginc"
            #include "AutoLight.cginc"
            #include "Lighting.cginc"
            #include "UnityPBSLighting.cginc"
            #include "UnityStandardBRDF.cginc"
			#include "Libraries/AmbientLight.cginc"

			struct appdata {
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				float3 normal : NORMAL;
				float4 tangent : TANGENT;
			};

			struct v2f {
				float2 uv0 : TEXCOORD0;
				float2 uv1 : TEXCOORD1;
				float4 vertex : SV_POSITION;
				float3 normalDir : NORMAL;
				float3 tangentDir : TANGENT0;
				float3 bitangentDir : TANGENT1;
				float4 posWorld : TEXCOORD2;				
			};

			sampler2D _MainTex; float4 _MainTex_ST;
			sampler2D _ToonRamp; float4 _ToonRamp_ST;
			sampler2D _Emission; float4 _Emission_ST;
			sampler2D _NormalMap; float4 _NormalMap_ST;
			float _NormalScale;
			
			v2f vert (appdata v) {
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv0 = TRANSFORM_TEX(v.uv, _MainTex);
				o.uv1 = TRANSFORM_TEX(v.uv, _NormalMap);

				// TBN for dot(L,N)/lambert light later
				o.normalDir = UnityObjectToWorldNormal(v.normal);
                o.tangentDir = normalize(mul(unity_ObjectToWorld, float4(v.tangent.xyz, 0.0)).xyz);
                o.bitangentDir = normalize(cross(o.normalDir, o.tangentDir) * v.tangent.w);
				o.posWorld = mul(unity_ObjectToWorld, v.vertex);

				// why even?
				// o.normalDir = normalize(o.normalDir);
				
				return o;
			}
			
			fixed4 frag (v2f i, float facing : VFACE) : SV_Target {
				// float faceSign = ( facing >= 0 ? 1 : -1 );
				// i.normalDir *= faceSign;

				// tangent space transform
				float3x3 tbn = float3x3(i.tangentDir, i.bitangentDir, i.normalDir);

				half3 normalMap = UnpackNormal(tex2D(_NormalMap, i.uv0)); 

				// Perturb the normals
				float3 normalDir = normalize(mul(normalMap, tbn));

				// light direction from world space light
                // float3 lightDir = normalize(lerp(_WorldSpaceLightPos0.xyz, ,_WorldSpaceLightPos0.w));
				float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);

				// light color and attenuation for important color-y things
				float3 lightColor = _LightColor0.rgb;				
				UNITY_LIGHT_ATTENUATION(attenuation, i, i.posWorld.xyz);

				float3 directLighting = lightColor * attenuation;

				// lambert (L dot N)
				float lightShading = dot(lightDir, normalDir);
				float3 indirectShading = Luminance(ShadeSH9(half4(1, 1, 1, 1)));

				float2 rampUV = float2(lightShading, lightShading);

				// get the ramp, diagonally, based on the light shading amount
				fixed4 ramp = tex2D(_ToonRamp, rampUV);

				// indirect ramp
				// inverse of grayscale ramp * ambient spherical harmonic
				// fixed3 indirectLighting = (Luminance(ramp)*indirectShading);

				// real samplers
				fixed4 baseColor = tex2D(_MainTex, i.uv0);
				fixed4 emission = tex2D(_Emission, i.uv0);
				
				// now the final colors,
				fixed3 final = baseColor.rgb;

				// mix the ramp
				final *= ramp;
				// mix emission
				// final = saturate(final + emission);
				// final = ramp;

				return fixed4(final, baseColor.a);
			}
			ENDCG
		}
		Pass {
			Name "FORWARD_DELTA"
			Tags { "LightMode" = "ForwardAdd" }
			Blend One One
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			// make fog work
			#pragma multi_compile_fog
			// #pragma multi_compile_fwdadd_fullshadows
			
			#include "UnityCG.cginc"
            #include "AutoLight.cginc"
            #include "Lighting.cginc"
            #include "UnityPBSLighting.cginc"
            #include "UnityStandardBRDF.cginc"

			struct appdata {
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				float3 normal : NORMAL;
				float4 tangent : TANGENT;
			};

			struct v2f {
				float2 uv0 : TEXCOORD0;
				float2 uv1 : TEXCOORD1;
				float4 vertex : SV_POSITION;
				float3 normalDir : NORMAL;
				float3 tangentDir : TANGENT0;
				float3 bitangentDir : TANGENT1;
				float4 posWorld : TEXCOORD2;				
			};

			sampler2D _MainTex; float4 _MainTex_ST;
			sampler2D _ToonRamp; float4 _ToonRamp_ST;
			sampler2D _Emission; float4 _Emission_ST;
			sampler2D _NormalMap; float4 _NormalMap_ST;
			
			v2f vert (appdata v) {
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv0 = TRANSFORM_TEX(v.uv, _MainTex);
				o.uv1 = TRANSFORM_TEX(v.uv, _NormalMap);

				// TBN for dot(L,N)/lambert light later
				o.normalDir = UnityObjectToWorldNormal(v.normal);
                o.tangentDir = normalize(mul(unity_ObjectToWorld, float4(v.tangent.xyz, 0.0)).xyz);
                o.bitangentDir = normalize(cross(o.normalDir, o.tangentDir) * v.tangent.w);
				o.posWorld = mul(unity_ObjectToWorld, v.vertex);

				// why even?
				// o.normalDir = normalize(o.normalDir);
				
				return o;
			}
			
			fixed4 frag (v2f i, float facing : VFACE) : SV_Target {
				// float faceSign = ( facing >= 0 ? 1 : -1 );
				// i.normalDir *= faceSign;

				// tangent space transform
				float3x3 tbn = float3x3(i.tangentDir, i.bitangentDir, i.normalDir);

				float3 normalMap = UnpackNormal(tex2D(_NormalMap, i.uv1));

				// Perturb the normals
				float3 normalDir = normalize(mul(normalMap, tbn));

				// light direction from world space light
                // float3 lightDir = normalize(lerp(_WorldSpaceLightPos0.xyz, ,_WorldSpaceLightPos0.w));
				float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);

				// light color and attenuation for important color-y things
				float3 lightColor = _LightColor0.rgb;				
				UNITY_LIGHT_ATTENUATION(attenuation, i, i.posWorld.xyz);
				
				// lambert (L dot N)
				float3 lightShading = dot(lightDir, normalDir);
				
				// delta light contribution
				float lightContribution = dot(normalize(_WorldSpaceLightPos0.xyz - i.posWorld.xyz),normalDir)*attenuation;
				float3 directContribution = floor(saturate(lightContribution) * 2.0);
				float4 ramp = tex2D(_ToonRamp, float2(directContribution.x, directContribution.x));

				// real samplers
				fixed4 baseColor = tex2D(_MainTex, i.uv0);
				
				// now the final colors,
				fixed4 final = baseColor;

				final.rgb *= lerp(final.rgb * ramp.rgb, _LightColor0.rgb, saturate(directContribution * attenuation));

				return final;
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
            #include "AutoLight.cginc"
            #pragma fragmentoption ARB_precision_hint_fastest
            #pragma multi_compile_shadowcaster
            #pragma only_renderers d3d9 d3d11 glcore gles 
            #pragma target 3.0
            uniform sampler2D _MainTex; uniform float4 _MainTex_ST;
            struct VertexInput {
                float4 vertex : POSITION;
                float2 texcoord0 : TEXCOORD0;
            };
            struct VertexOutput {
                V2F_SHADOW_CASTER;
                float2 uv0 : TEXCOORD1;
            };
            VertexOutput vert (VertexInput v) {
                VertexOutput o = (VertexOutput)0;
                o.uv0 = v.texcoord0;
                o.pos = UnityObjectToClipPos( v.vertex );
                TRANSFER_SHADOW_CASTER(o)
                return o;
            }
            float4 frag(VertexOutput i, float facing : VFACE) : COLOR {
                float isFrontFace = ( facing >= 0 ? 1 : 0 );
                float faceSign = ( facing >= 0 ? 1 : -1 );
                SHADOW_CASTER_FRAGMENT(i)
            }
            ENDCG
        }
	}
}
