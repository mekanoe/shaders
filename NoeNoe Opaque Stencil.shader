Shader "Okano/NoeNoe/Opaque Stencil" {
    Properties {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Main texture (RGB)", 2D) = "white" {}
        _CrossfadeSurfaceOverlay ("Crossfade Surface / Overlay", Range(0, 2)) = 1
        _TileOverlay ("Tile Overlay", 2D) = "white" {}
        _TileSpeedX ("Tile Speed X", Range(-1, 1)) = 0
        _TileSpeedY ("Tile Speed Y", Range(-1, 1)) = 0
        _CubemapOverlay ("Cubemap Overlay", Cube) = "_Skybox" {}
        _CrossfadeTileCubemap ("Crossfade Tile / Cubemap", Range(0, 2)) = 0
        [MaterialToggle] _DynamicToonLighting ("Dynamic Toon Lighting", Float ) = 1
        _StaticToonLight ("Static Toon Light", Vector) = (0,0,0,0)
        _Ramp ("Ramp", 2D) = "white" {}
        [MaterialToggle] _NoLightShading ("No Light Shading", Float ) = 0
        _EmissionMap ("Emission Map", 2D) = "white" {}
        _Emission ("Emission", Range(0, 10)) = 0
        _Intensity ("Intensity", Range(0, 10)) = 1
        _NormalMap ("Normal Map", 2D) = "bump" {}
        _OutlineWidth ("Outline Width", Float ) = 0
        _OutlineColor ("Outline Color", Color) = (0,0,0,1)
        [MaterialToggle] _ScreenSpaceOutline ("Screen-Space Outline", Float ) = 0
        _Ref ("Stencil Ref", int) = 1
    }
    SubShader {
        Tags {
            "RenderType"="Opaque"
        }
        
        Stencil {
            Ref [_Ref]
            Comp equal
        }

        Pass {
            Name "Outline"
            Cull Front
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #define _GLOSSYENV 1
            #include "UnityCG.cginc"
            #include "UnityPBSLighting.cginc"
            #include "UnityStandardBRDF.cginc"
            #pragma fragmentoption ARB_precision_hint_fastest
            #pragma multi_compile_shadowcaster
            #pragma only_renderers d3d9 d3d11 glcore gles 
            #pragma target 3.0
            uniform float _OutlineWidth;
            uniform fixed _ScreenSpaceOutline;
            uniform float4 _OutlineColor;
            struct VertexInput {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };
            struct VertexOutput {
                float4 pos : SV_POSITION;
                float4 posWorld : TEXCOORD0;
            };
            VertexOutput vert (VertexInput v) {
                VertexOutput o = (VertexOutput)0;
                o.posWorld = mul(unity_ObjectToWorld, v.vertex);
                float node_8257 = (_OutlineWidth*0.001);
                o.pos = UnityObjectToClipPos( float4(v.vertex.xyz + v.normal*lerp( node_8257, (distance(_WorldSpaceCameraPos,mul(unity_ObjectToWorld, v.vertex).rgb)*node_8257), _ScreenSpaceOutline ),1) );
                return o;
            }
            float4 frag(VertexOutput i, float facing : VFACE) : COLOR {
                float isFrontFace = ( facing >= 0 ? 1 : 0 );
                float faceSign = ( facing >= 0 ? 1 : -1 );
                return fixed4(_OutlineColor.rgb,0);
            }
            ENDCG
        }
        Pass {
            Name "FORWARD"
            Tags {
                "LightMode"="ForwardBase"
            }
            Cull Off
            
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #define UNITY_PASS_FORWARDBASE
            #define _GLOSSYENV 1
            #include "UnityCG.cginc"
            #include "AutoLight.cginc"
            #include "Lighting.cginc"
            #include "UnityPBSLighting.cginc"
            #include "UnityStandardBRDF.cginc"
            #pragma multi_compile_fwdbase_fullshadows
            #pragma only_renderers d3d9 d3d11 glcore gles 
            #pragma target 3.0
            uniform float4 _TimeEditor;
            uniform float4 _Color;
            uniform sampler2D _TileOverlay; uniform float4 _TileOverlay_ST;
            uniform sampler2D _MainTex; uniform float4 _MainTex_ST;
            uniform float _CrossfadeSurfaceOverlay;
            uniform float _TileSpeedX;
            uniform float _TileSpeedY;
            uniform samplerCUBE _CubemapOverlay;
            uniform float _CrossfadeTileCubemap;
            uniform sampler2D _EmissionMap; uniform float4 _EmissionMap_ST;
            uniform float _Emission;
            uniform sampler2D _NormalMap; uniform float4 _NormalMap_ST;
            uniform float _Intensity;
            float3 Function_node_3693( float3 normal ){
            return ShadeSH9(half4(normal, 1.0));
            
            }
            
            uniform fixed _NoLightShading;
            uniform float4 _StaticToonLight;
            uniform fixed _DynamicToonLighting;
            uniform sampler2D _Ramp; uniform float4 _Ramp_ST;
            struct VertexInput {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float2 texcoord0 : TEXCOORD0;
            };
            struct VertexOutput {
                float4 pos : SV_POSITION;
                float2 uv0 : TEXCOORD0;
                float4 posWorld : TEXCOORD1;
                float3 normalDir : TEXCOORD2;
                float3 tangentDir : TEXCOORD3;
                float3 bitangentDir : TEXCOORD4;
                LIGHTING_COORDS(5,6)
            };
            VertexOutput vert (VertexInput v) {
                VertexOutput o = (VertexOutput)0;
                o.uv0 = v.texcoord0;
                o.normalDir = UnityObjectToWorldNormal(v.normal);
                o.tangentDir = normalize( mul( unity_ObjectToWorld, float4( v.tangent.xyz, 0.0 ) ).xyz );
                o.bitangentDir = normalize(cross(o.normalDir, o.tangentDir) * v.tangent.w);
                o.posWorld = mul(unity_ObjectToWorld, v.vertex);
                float3 lightColor = _LightColor0.rgb;
                o.pos = UnityObjectToClipPos( v.vertex );
                TRANSFER_VERTEX_TO_FRAGMENT(o)
                return o;
            }
            float4 frag(VertexOutput i, float facing : VFACE) : COLOR {
                float isFrontFace = ( facing >= 0 ? 1 : 0 );
                float faceSign = ( facing >= 0 ? 1 : -1 );
                i.normalDir = normalize(i.normalDir);
                i.normalDir *= faceSign;
                float3x3 tangentTransform = float3x3( i.tangentDir, i.bitangentDir, i.normalDir);
                float3 viewDirection = normalize(_WorldSpaceCameraPos.xyz - i.posWorld.xyz);
                float3 _NormalMap_var = UnpackNormal(tex2D(_NormalMap,TRANSFORM_TEX(i.uv0, _NormalMap)));
                float3 normalLocal = _NormalMap_var.rgb;
                float3 normalDirection = normalize(mul( normalLocal, tangentTransform )); // Perturbed normals
                float3 lightDirection = normalize(_WorldSpaceLightPos0.xyz);
                float3 lightColor = _LightColor0.rgb;
////// Lighting:
                float attenuation = LIGHT_ATTENUATION(i);
////// Emissive:
                float4 _EmissionMap_var = tex2D(_EmissionMap,TRANSFORM_TEX(i.uv0, _EmissionMap));
                float3 emissive = (_EmissionMap_var.rgb*_Emission);
                float2 node_4737 = float2(saturate(dot(normalDirection,_StaticToonLight.rgb)),0.2);
                float4 node_6405 = tex2D(_Ramp,TRANSFORM_TEX(node_4737, _Ramp));
                float node_9074 = 3.0;
                float2 node_2538 = float2(saturate(dot(normalDirection,lightDirection)),0.2);
                float4 _Ramp_copy = tex2D(_Ramp,TRANSFORM_TEX(node_2538, _Ramp));
                float node_9409 = 3.0;
                float node_7920 = 1.0;
                float node_6078 = 1.0;
                float3 node_769 = viewDirection.rgb;
                float node_9795 = 0.1;
                float4 node_47 = _Time + _TimeEditor;
                float3 node_4810 = viewDirection.brg;
                float2 node_1431 = ((float2((node_9795*_TileSpeedX),(node_9795*_TileSpeedY))*node_47.g)+(1.0 - float2(((atan2(node_4810.r,node_4810.g)/6.28318530718)+0.5),(acos(node_4810.b)/(-1*3.141592654)))).rg);
                float4 _TileOverlay_var = tex2D(_TileOverlay,TRANSFORM_TEX(node_1431, _TileOverlay));
                float4 _MainTex_var = tex2D(_MainTex,TRANSFORM_TEX(i.uv0, _MainTex));
                float3 finalColor = emissive + (_Intensity*saturate((lerp( Function_node_3693( float3(0,1,0) ), 0.0, _NoLightShading )+(_LightColor0.rgb*attenuation)))*(floor(saturate((dot(node_6405.rgb,float3(0.3,0.59,0.11))+0.8)) * node_9074) / (node_9074 - 1)-0.5)*lerp( 1.0, (floor(saturate((dot(_Ramp_copy.rgb,float3(0.3,0.59,0.11))+0.8)) * node_9409) / (node_9409 - 1)-0.5), _DynamicToonLighting )*lerp(lerp(((lerp(float3(node_7920,node_7920,node_7920),(lerp(float3(node_6078,node_6078,node_6078),(texCUBE(_CubemapOverlay,float3(node_769.r,(node_769.g*(-1.0)),node_769.b)).rgb*2.0),saturate(_CrossfadeTileCubemap))*lerp(float3(node_6078,node_6078,node_6078),_TileOverlay_var.rgb,saturate((node_6078+(1.0 - _CrossfadeTileCubemap))))),saturate(_CrossfadeSurfaceOverlay))*lerp(float3(node_7920,node_7920,node_7920),_MainTex_var.rgb,saturate((node_7920+(1.0 - _CrossfadeSurfaceOverlay)))))*_Color.rgb*1.0),dot(((lerp(float3(node_7920,node_7920,node_7920),(lerp(float3(node_6078,node_6078,node_6078),(texCUBE(_CubemapOverlay,float3(node_769.r,(node_769.g*(-1.0)),node_769.b)).rgb*2.0),saturate(_CrossfadeTileCubemap))*lerp(float3(node_6078,node_6078,node_6078),_TileOverlay_var.rgb,saturate((node_6078+(1.0 - _CrossfadeTileCubemap))))),saturate(_CrossfadeSurfaceOverlay))*lerp(float3(node_7920,node_7920,node_7920),_MainTex_var.rgb,saturate((node_7920+(1.0 - _CrossfadeSurfaceOverlay)))))*_Color.rgb*1.0),float3(0.3,0.59,0.11)),(-0.5)),dot(lerp(((lerp(float3(node_7920,node_7920,node_7920),(lerp(float3(node_6078,node_6078,node_6078),(texCUBE(_CubemapOverlay,float3(node_769.r,(node_769.g*(-1.0)),node_769.b)).rgb*2.0),saturate(_CrossfadeTileCubemap))*lerp(float3(node_6078,node_6078,node_6078),_TileOverlay_var.rgb,saturate((node_6078+(1.0 - _CrossfadeTileCubemap))))),saturate(_CrossfadeSurfaceOverlay))*lerp(float3(node_7920,node_7920,node_7920),_MainTex_var.rgb,saturate((node_7920+(1.0 - _CrossfadeSurfaceOverlay)))))*_Color.rgb*1.0),dot(((lerp(float3(node_7920,node_7920,node_7920),(lerp(float3(node_6078,node_6078,node_6078),(texCUBE(_CubemapOverlay,float3(node_769.r,(node_769.g*(-1.0)),node_769.b)).rgb*2.0),saturate(_CrossfadeTileCubemap))*lerp(float3(node_6078,node_6078,node_6078),_TileOverlay_var.rgb,saturate((node_6078+(1.0 - _CrossfadeTileCubemap))))),saturate(_CrossfadeSurfaceOverlay))*lerp(float3(node_7920,node_7920,node_7920),_MainTex_var.rgb,saturate((node_7920+(1.0 - _CrossfadeSurfaceOverlay)))))*_Color.rgb*1.0),float3(0.3,0.59,0.11)),(-0.5)),float3(0.3,0.59,0.11)),(1.0 - _Color.a)));
                return fixed4(finalColor,1);
            }
            ENDCG
        }
        Pass {
            Name "FORWARD_DELTA"
            Tags {
                "LightMode"="ForwardAdd"
            }
            Blend One One
            Cull Off
            
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #define UNITY_PASS_FORWARDADD
            #define _GLOSSYENV 1
            #include "UnityCG.cginc"
            #include "AutoLight.cginc"
            #include "Lighting.cginc"
            #include "UnityPBSLighting.cginc"
            #include "UnityStandardBRDF.cginc"
            #pragma multi_compile_fwdadd_fullshadows
            #pragma only_renderers d3d9 d3d11 glcore gles 
            #pragma target 3.0
            uniform float4 _TimeEditor;
            uniform float4 _Color;
            uniform sampler2D _TileOverlay; uniform float4 _TileOverlay_ST;
            uniform sampler2D _MainTex; uniform float4 _MainTex_ST;
            uniform float _CrossfadeSurfaceOverlay;
            uniform float _TileSpeedX;
            uniform float _TileSpeedY;
            uniform samplerCUBE _CubemapOverlay;
            uniform float _CrossfadeTileCubemap;
            uniform sampler2D _EmissionMap; uniform float4 _EmissionMap_ST;
            uniform float _Emission;
            uniform sampler2D _NormalMap; uniform float4 _NormalMap_ST;
            uniform float _Intensity;
            float3 Function_node_3693( float3 normal ){
            return ShadeSH9(half4(normal, 1.0));
            
            }
            
            uniform fixed _NoLightShading;
            uniform float4 _StaticToonLight;
            uniform fixed _DynamicToonLighting;
            uniform sampler2D _Ramp; uniform float4 _Ramp_ST;
            struct VertexInput {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float2 texcoord0 : TEXCOORD0;
            };
            struct VertexOutput {
                float4 pos : SV_POSITION;
                float2 uv0 : TEXCOORD0;
                float4 posWorld : TEXCOORD1;
                float3 normalDir : TEXCOORD2;
                float3 tangentDir : TEXCOORD3;
                float3 bitangentDir : TEXCOORD4;
                LIGHTING_COORDS(5,6)
            };
            VertexOutput vert (VertexInput v) {
                VertexOutput o = (VertexOutput)0;
                o.uv0 = v.texcoord0;
                o.normalDir = UnityObjectToWorldNormal(v.normal);
                o.tangentDir = normalize( mul( unity_ObjectToWorld, float4( v.tangent.xyz, 0.0 ) ).xyz );
                o.bitangentDir = normalize(cross(o.normalDir, o.tangentDir) * v.tangent.w);
                o.posWorld = mul(unity_ObjectToWorld, v.vertex);
                float3 lightColor = _LightColor0.rgb;
                o.pos = UnityObjectToClipPos( v.vertex );
                TRANSFER_VERTEX_TO_FRAGMENT(o)
                return o;
            }
            float4 frag(VertexOutput i, float facing : VFACE) : COLOR {
                float isFrontFace = ( facing >= 0 ? 1 : 0 );
                float faceSign = ( facing >= 0 ? 1 : -1 );
                i.normalDir = normalize(i.normalDir);
                i.normalDir *= faceSign;
                float3x3 tangentTransform = float3x3( i.tangentDir, i.bitangentDir, i.normalDir);
                float3 viewDirection = normalize(_WorldSpaceCameraPos.xyz - i.posWorld.xyz);
                float3 _NormalMap_var = UnpackNormal(tex2D(_NormalMap,TRANSFORM_TEX(i.uv0, _NormalMap)));
                float3 normalLocal = _NormalMap_var.rgb;
                float3 normalDirection = normalize(mul( normalLocal, tangentTransform )); // Perturbed normals
                float3 lightDirection = normalize(lerp(_WorldSpaceLightPos0.xyz, _WorldSpaceLightPos0.xyz - i.posWorld.xyz,_WorldSpaceLightPos0.w));
                float3 lightColor = _LightColor0.rgb;
////// Lighting:
                float attenuation = LIGHT_ATTENUATION(i);
                float2 node_4737 = float2(saturate(dot(normalDirection,_StaticToonLight.rgb)),0.2);
                float4 node_6405 = tex2D(_Ramp,TRANSFORM_TEX(node_4737, _Ramp));
                float node_9074 = 3.0;
                float2 node_2538 = float2(saturate(dot(normalDirection,lightDirection)),0.2);
                float4 _Ramp_copy = tex2D(_Ramp,TRANSFORM_TEX(node_2538, _Ramp));
                float node_9409 = 3.0;
                float node_7920 = 1.0;
                float node_6078 = 1.0;
                float3 node_769 = viewDirection.rgb;
                float node_9795 = 0.1;
                float4 node_47 = _Time + _TimeEditor;
                float3 node_4810 = viewDirection.brg;
                float2 node_1431 = ((float2((node_9795*_TileSpeedX),(node_9795*_TileSpeedY))*node_47.g)+(1.0 - float2(((atan2(node_4810.r,node_4810.g)/6.28318530718)+0.5),(acos(node_4810.b)/(-1*3.141592654)))).rg);
                float4 _TileOverlay_var = tex2D(_TileOverlay,TRANSFORM_TEX(node_1431, _TileOverlay));
                float4 _MainTex_var = tex2D(_MainTex,TRANSFORM_TEX(i.uv0, _MainTex));
                float3 finalColor = (_Intensity*saturate((lerp( Function_node_3693( float3(0,1,0) ), 0.0, _NoLightShading )+(_LightColor0.rgb*attenuation)))*(floor(saturate((dot(node_6405.rgb,float3(0.3,0.59,0.11))+0.8)) * node_9074) / (node_9074 - 1)-0.5)*lerp( 1.0, (floor(saturate((dot(_Ramp_copy.rgb,float3(0.3,0.59,0.11))+0.8)) * node_9409) / (node_9409 - 1)-0.5), _DynamicToonLighting )*lerp(lerp(((lerp(float3(node_7920,node_7920,node_7920),(lerp(float3(node_6078,node_6078,node_6078),(texCUBE(_CubemapOverlay,float3(node_769.r,(node_769.g*(-1.0)),node_769.b)).rgb*2.0),saturate(_CrossfadeTileCubemap))*lerp(float3(node_6078,node_6078,node_6078),_TileOverlay_var.rgb,saturate((node_6078+(1.0 - _CrossfadeTileCubemap))))),saturate(_CrossfadeSurfaceOverlay))*lerp(float3(node_7920,node_7920,node_7920),_MainTex_var.rgb,saturate((node_7920+(1.0 - _CrossfadeSurfaceOverlay)))))*_Color.rgb*1.0),dot(((lerp(float3(node_7920,node_7920,node_7920),(lerp(float3(node_6078,node_6078,node_6078),(texCUBE(_CubemapOverlay,float3(node_769.r,(node_769.g*(-1.0)),node_769.b)).rgb*2.0),saturate(_CrossfadeTileCubemap))*lerp(float3(node_6078,node_6078,node_6078),_TileOverlay_var.rgb,saturate((node_6078+(1.0 - _CrossfadeTileCubemap))))),saturate(_CrossfadeSurfaceOverlay))*lerp(float3(node_7920,node_7920,node_7920),_MainTex_var.rgb,saturate((node_7920+(1.0 - _CrossfadeSurfaceOverlay)))))*_Color.rgb*1.0),float3(0.3,0.59,0.11)),(-0.5)),dot(lerp(((lerp(float3(node_7920,node_7920,node_7920),(lerp(float3(node_6078,node_6078,node_6078),(texCUBE(_CubemapOverlay,float3(node_769.r,(node_769.g*(-1.0)),node_769.b)).rgb*2.0),saturate(_CrossfadeTileCubemap))*lerp(float3(node_6078,node_6078,node_6078),_TileOverlay_var.rgb,saturate((node_6078+(1.0 - _CrossfadeTileCubemap))))),saturate(_CrossfadeSurfaceOverlay))*lerp(float3(node_7920,node_7920,node_7920),_MainTex_var.rgb,saturate((node_7920+(1.0 - _CrossfadeSurfaceOverlay)))))*_Color.rgb*1.0),dot(((lerp(float3(node_7920,node_7920,node_7920),(lerp(float3(node_6078,node_6078,node_6078),(texCUBE(_CubemapOverlay,float3(node_769.r,(node_769.g*(-1.0)),node_769.b)).rgb*2.0),saturate(_CrossfadeTileCubemap))*lerp(float3(node_6078,node_6078,node_6078),_TileOverlay_var.rgb,saturate((node_6078+(1.0 - _CrossfadeTileCubemap))))),saturate(_CrossfadeSurfaceOverlay))*lerp(float3(node_7920,node_7920,node_7920),_MainTex_var.rgb,saturate((node_7920+(1.0 - _CrossfadeSurfaceOverlay)))))*_Color.rgb*1.0),float3(0.3,0.59,0.11)),(-0.5)),float3(0.3,0.59,0.11)),(1.0 - _Color.a)));
                return fixed4(finalColor * 1,0);
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
            #pragma fragmentoption ARB_precision_hint_fastest
            #pragma multi_compile_shadowcaster
            #pragma only_renderers d3d9 d3d11 glcore gles 
            #pragma target 3.0
            struct VertexInput {
                float4 vertex : POSITION;
            };
            struct VertexOutput {
                V2F_SHADOW_CASTER;
            };
            VertexOutput vert (VertexInput v) {
                VertexOutput o = (VertexOutput)0;
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
        Pass {
            Name "Meta"
            Tags {
                "LightMode"="Meta"
            }
            Cull Off
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #define UNITY_PASS_META 1
            #define _GLOSSYENV 1
            #include "UnityCG.cginc"
            #include "UnityPBSLighting.cginc"
            #include "UnityStandardBRDF.cginc"
            #include "UnityMetaPass.cginc"
            #pragma fragmentoption ARB_precision_hint_fastest
            #pragma multi_compile_shadowcaster
            #pragma only_renderers d3d9 d3d11 glcore gles 
            #pragma target 3.0
            uniform sampler2D _EmissionMap; uniform float4 _EmissionMap_ST;
            uniform float _Emission;
            struct VertexInput {
                float4 vertex : POSITION;
                float2 texcoord0 : TEXCOORD0;
                float2 texcoord1 : TEXCOORD1;
                float2 texcoord2 : TEXCOORD2;
            };
            struct VertexOutput {
                float4 pos : SV_POSITION;
                float2 uv0 : TEXCOORD0;
            };
            VertexOutput vert (VertexInput v) {
                VertexOutput o = (VertexOutput)0;
                o.uv0 = v.texcoord0;
                o.pos = UnityMetaVertexPosition(v.vertex, v.texcoord1.xy, v.texcoord2.xy, unity_LightmapST, unity_DynamicLightmapST );
                return o;
            }
            float4 frag(VertexOutput i, float facing : VFACE) : SV_Target {
                float isFrontFace = ( facing >= 0 ? 1 : 0 );
                float faceSign = ( facing >= 0 ? 1 : -1 );
                UnityMetaInput o;
                UNITY_INITIALIZE_OUTPUT( UnityMetaInput, o );
                
                float4 _EmissionMap_var = tex2D(_EmissionMap,TRANSFORM_TEX(i.uv0, _EmissionMap));
                o.Emission = (_EmissionMap_var.rgb*_Emission);
                
                float3 diffColor = float3(0,0,0);
                o.Albedo = diffColor;
                
                return UnityMetaFragment( o );
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
    CustomEditor "ShaderForgeMaterialInspector"
}
