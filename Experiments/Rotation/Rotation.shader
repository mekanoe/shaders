// learning stuffsss
Shader "Hidden/Okano/Experiments/Rotation"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_RotationSpeed ("Rotation Speed", Float) = 1
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
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				UNITY_FOG_COORDS(1)
				float4 vertex : SV_POSITION;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			float _RotationSpeed;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				v.uv.xy -= 0.5;
				float sinX = sin ( _RotationSpeed * _Time );
				float cosX = cos ( _RotationSpeed * _Time );
				float sinY = sin ( _RotationSpeed * _Time );
				float2x2 rotationMatrix = float2x2( cosX, -sinX, sinY, cosX);
				rotationMatrix *=0.5;
                rotationMatrix +=0.5;
                rotationMatrix = rotationMatrix * 2-1;
				v.uv.xy = mul ( v.uv.xy, rotationMatrix );
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				// o.uv += 0.5;
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
