Shader "Okano/CryCamo" {
    Properties {
        
        [Header(Texture 1)]
        _Tex1 ("Texture 1", 2D) = "white" {}
        [NoScaleOffset] _GlossMap1 ("Texture 1 Gloss Map", 2D) = "black" {}
        [NoScaleOffset] _MetalMap1 ("Texture 1 Metallic Map", 2D) = "black" {}
        [NoScaleOffset][HDR] _EmissionMap1 ("Texture 1 Emission Map", 2D) = "black" {}
        [NoScaleOffset][Normal] _NormalMap1 ("Texture 1 Normal Map", 2D) = "bump" {}
        
        [Header(Texture 2)]
        _Tex2 ("Texture 2", 2D) = "white" {}
        [NoScaleOffset] _GlossMap2 ("Texture 2 Gloss Map", 2D) = "black" {}
        [NoScaleOffset] _MetalMap2 ("Texture 2 Metallic Map", 2D) = "black" {}
        [NoScaleOffset][HDR] _EmissionMap2 ("Texture 2 Emission Map", 2D) = "black" {}
        [NoScaleOffset][Normal] _NormalMap2 ("Texture 2 Normal Map", 2D) = "bump" {}
        

        [Header(Miscellaneous)]
        _Tint ("Tint", Color) = (1,1,1,1)
        _EmissionMultipier ("Emission Multiplier", Range(0, 1)) = 0.0
        [Toggle] _EmissionFromAlb ("Emission from Albedo", float) = 0.0
        [Toggle] _TintEmission ("Also Tint Emission", float) = 0.0
        _SwitchSpeed ("Switch Speed", float) = 0.0
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

        sampler2D _Tex1;
        sampler2D _GlossMap1;
        sampler2D _MetalMap1;
        sampler2D _EmissionMap1;
        sampler2D _NormalMap1;
        sampler2D _Tex2;
        sampler2D _GlossMap2;
        sampler2D _MetalMap2;
        sampler2D _EmissionMap2;
        sampler2D _NormalMap2;
        

        float _SwitchSpeed;
        float _EmissionMultipier;
        float4 _Tint;
        float _EmissionFromAlb;
        float _TintEmission;

        struct Input {
            float2 uv_Tex1;
            float2 uv_Tex2;
        };

        void surf (Input IN, inout SurfaceOutputStandard o) {
            float time = _Time * _SwitchSpeed;
            float position = saturate((sin(time) + 1.0) * 0.5);

            fixed4 c1 = tex2D(_Tex1, IN.uv_Tex1);
            fixed4 c1g = tex2D(_GlossMap1, IN.uv_Tex1);
            fixed4 c1m = tex2D(_MetalMap1, IN.uv_Tex1);
            fixed4 c1e = tex2D(_EmissionMap1, IN.uv_Tex1);
            fixed4 c1n = tex2D(_NormalMap1, IN.uv_Tex1);
            fixed4 c2 = tex2D(_Tex2, IN.uv_Tex2);
            fixed4 c2g = tex2D(_GlossMap2, IN.uv_Tex2);			
            fixed4 c2m = tex2D(_MetalMap2, IN.uv_Tex2);
            fixed4 c2e = tex2D(_EmissionMap2, IN.uv_Tex2);
            fixed4 c2n = tex2D(_NormalMap2, IN.uv_Tex2);
            
            
            // float3 f3Pos = float3(position, position, position);
            
            o.Albedo = saturate(lerp(c1.rgb, c2.rgb, position)) * (_Tint.rgb * _Tint.a);
            o.Metallic = saturate(lerp(c1m.r, c2m.r, position));
            o.Smoothness = saturate(lerp(c1g.r, c2g.r, position));
            o.Normal = lerp(c1n, c2n, position);

            // if (_EmissionFromAlb) {
            //     o.Emission = o.Albedo * _EmissionMultipier;
            // } else {
            //     o.Emission = (saturate(lerp(c1e.rgb, c2e.rgb, position)) * (_TintEmission * (_Tint.rgb * _Tint.a)) * _EmissionMultipier);
            // }
        }
        ENDCG
    }
    FallBack "Diffuse"
}
