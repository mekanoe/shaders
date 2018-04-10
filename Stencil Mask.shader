// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Okano/Stencil Mask"
{
    Properties {
        _Ref("Stencil Ref",int) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue"="Geometry-1" }
        ColorMask 0
        ZWrite off
        Cull Front
        
        Stencil
        {
            Ref [_Ref]
            Comp always
            Pass replace
        }
        
        Pass
        {
            ZTest Less
        
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            struct appdata
            {
                float4 vertex : POSITION;
            };
            struct v2f
            {
                float4 pos : SV_POSITION;
            };
            v2f vert(appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                return o;
            }
            half4 frag(v2f i) : COLOR
            {
                return half4(1,1,0,1);
            }
            ENDCG
        }
    } 
}