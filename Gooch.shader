Shader "Okano/Gooch"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_TopLight ("Top Light", Color) = (1,1,0,1)
		_BottomLight ("Bottom Light", Color) = (0,0,1,1)
		_LightIntensity ("Light Intensity", Range(0,1)) = 0.5
		[Toggle] _Grayscale ("Grayscale Texture?", Float) = 0
		[Header(Outline)]
		_OutlineColor ("Outline Color", Color) = (0,0,0,1)
		_OutlineWidth ("Outline Width", Float) = 1
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100
		Cull off
		// Pass {
        //     Name "Outline"
        //     Tags {
        //     }
        //     Cull Front
            
        //     CGPROGRAM
        //     #pragma vertex vert
        //     #pragma fragment frag
        //     #define _GLOSSYENV 1
        //     #include "UnityCG.cginc"
        //     #include "UnityPBSLighting.cginc"
        //     #include "UnityStandardBRDF.cginc"
        //     #include "AutoLight.cginc"
        //     #pragma fragmentoption ARB_precision_hint_fastest
        //     #pragma multi_compile_shadowcaster
        //     #pragma only_renderers d3d9 d3d11 glcore gles 
        //     #pragma target 3.0
        //     uniform sampler2D _MainTex; uniform float4 _MainTex_ST;
        //     uniform float _OutlineWidth;
        //     uniform float4 _OutlineColor;
        //     struct VertexInput {
        //         float4 vertex : POSITION;
        //         float3 normal : NORMAL;
        //         float2 texcoord0 : TEXCOORD0;
        //     };
        //     struct VertexOutput {
        //         float4 pos : SV_POSITION;
        //         float2 uv0 : TEXCOORD0;
        //         float4 posWorld : TEXCOORD1;
        //     };
        //     VertexOutput vert (VertexInput v) {
        //         VertexOutput o = (VertexOutput)0;
        //         o.uv0 = v.texcoord0;
        //         o.posWorld = mul(unity_ObjectToWorld, v.vertex);
        //         float node_8257 = (_OutlineWidth*0.001);
        //         // float OutlineScale = lerp( node_8257, (distance(_WorldSpaceCameraPos,mul(unity_ObjectToWorld, v.vertex).rgb)*node_8257), _ScreenSpaceOutline );
        //         o.pos = UnityObjectToClipPos( float4(v.vertex.xyz + v.normal*node_8257,1) );
        //         return o;
        //     }
        //     float4 frag(VertexOutput i, float facing : VFACE) : COLOR {
        //         float isFrontFace = ( facing >= 0 ? 1 : 0 );
        //         float faceSign = ( facing >= 0 ? 1 : -1 );
        //         float4 _MainTex_var = tex2D(_MainTex,TRANSFORM_TEX(i.uv0, _MainTex));
        //         float SurfaceAlpha = _MainTex_var.a;
        //         float node_7192 = SurfaceAlpha;
        //         clip(node_7192 - 0.5);
        //         return fixed4(_OutlineColor.rgb,0);
        //     }
        //     ENDCG
        // }

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
				float3 normal : NORMAL;
				float4 tangent : TANGENT;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				UNITY_FOG_COORDS(1)
				float4 vertex : SV_POSITION;
				float3 normalDir : NORMAL;
				float3 tangentDir : TANGENT0;
				float3 bitangentDir : TANGENT1;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			float4 _TopLight;
			float4 _BottomLight;
			float _LightIntensity;
			float _Grayscale; 

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.normalDir = UnityObjectToWorldNormal(v.normal);
                o.tangentDir = normalize(mul(unity_ObjectToWorld, float4(v.tangent.xyz, 0.0)).xyz);
                o.bitangentDir = normalize(cross(o.normalDir, o.tangentDir) * v.tangent.w);
				UNITY_TRANSFER_FOG(o,o.vertex);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{	
				float lightPos = (i.vertex.y - 0.45) * 20 / 20;
				float lightAmount = saturate(dot(normalize(i.normalDir), normalize(_WorldSpaceLightPos0.xyz)) * 1.5 + 0.5);
				float lightAmount2 = saturate(dot(normalize(i.normalDir), normalize(float3(i.vertex.x, lightPos, i.vertex.z))));
				lightAmount = lerp(lightAmount2, lightAmount, lightAmount);

				// sample the texture
				fixed4 lightContribution = lerp(_BottomLight, _TopLight, lightAmount);
				fixed4 tex = tex2D(_MainTex, i.uv);
				fixed4 col = lightContribution * lerp(tex, Luminance(tex), _Grayscale);
				// col = lightAmount;
				// apply fog
				UNITY_APPLY_FOG(i.fogCoord, col);
				return col;
			}
			ENDCG
		}
	}
}
