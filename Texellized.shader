Shader "Okano/Texellized"
{
	Properties
	{
		_DistanceScale ("Separation Scale", Range(0,1)) = 1
		_DistanceDirectional ("X: TL, Y: TR, Z: RL", Vector) = (1, 0, 0, 0) 
		[HDR]_StartColor ("Minimum-ish Color", Color) = (1,0,1,1)
		[HDR]_EndColor ("Maximum-ish Color", Color) = (0,1,1,1)
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
			#pragma geometry geom 
			// make fog work
			#pragma multi_compile_fog
			
			#include "UnityCG.cginc"

			struct vertAttributes
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				float3 vertDist : TEXCOORD1;
				float4 worldPos : TEXCOORD2;
			};

			struct fragData
			{
				float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0;
				float3 vertDist : TEXCOORD1;
				float4 worldPos : TEXCOORD2;
			};

			float _DistanceScale;
			float4 _StartColor;
			float4 _EndColor;
			float3 _DistanceDirectional;
			
			
			vertAttributes vert (vertAttributes v) {
				fragData o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.worldPos = mul(unity_ObjectToWorld, v.vertex);
				o.uv = v.uv.xy;
				o.vertDist = v.vertDist;
				return o;
			}

			[maxvertexcount(3)]
			void geom ( triangle vertAttributes input[3], inout TriangleStream<fragData> o ) {
				vertAttributes thisTri = input[0];
				vertAttributes rightTri = input[1];
				vertAttributes leftTri = input[2];

				float TR = distance(thisTri.worldPos.xyz, rightTri.worldPos.xyz);
				float TL = distance(thisTri.worldPos.xyz, leftTri.worldPos.xyz);
				float RL = distance(rightTri.worldPos.xyz, leftTri.worldPos.xyz);

				float3 distances = float3(TR, TL, RL);
				thisTri.vertDist = rightTri.vertDist = leftTri.vertDist = distances;

				o.Append(thisTri);
				o.Append(rightTri);
				o.Append(leftTri);
				o.RestartStrip();
			}
			
			fixed4 frag (fragData i) : SV_Target {
				fixed size = i.vertDist * _DistanceDirectional * _DistanceScale;
				fixed4 col = lerp(_StartColor, _EndColor, saturate(size));

				return col;
			}
			ENDCG
		}
	}
}
