Shader "Okano/Transparent"
{
    Properties
    {
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "RenderQueue"="Transparent" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            #include "UnityCG.cginc"

            struct appdata
            {
            };

            struct v2f
            {
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            
            v2f vert (appdata v)
            {
                v2f o;
                return o;
            }
            
            fixed4 frag (v2f i) : SV_Target
            {
                discard;
                return fixed4(0,0,0,0);
            }
            ENDCG
        }
    }
}
