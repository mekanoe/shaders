Shader "Okano/NoeNoe/Toon Opaque Eyes" {
    Properties {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Main texture (RGB)", 2D) = "white" {}
        _StaticToonLight ("Static Toon Light", Vector) = (0,3,0,0)
        [MaterialToggle] _BillboardStaticLight ("Billboard Static Light", Float ) = 0
        _Ramp ("Ramp", 2D) = "white" {}
        _ToonContrast ("Toon Contrast", Range(0, 1)) = 0.25
        _EmissionMap ("Emission Map", 2D) = "white" {}
        _Emission ("Emission", Range(0, 10)) = 0
        _Intensity ("Intensity", Range(0, 10)) = 0.8
        _Saturation ("Saturation", Range(0, 1)) = 0.65
        _NormalMap ("Normal Map", 2D) = "bump" {}
        [HideInInspector]_Cutoff ("Alpha cutoff", Range(0,1)) = 0.5
        
        [Header(Rotation)]
        [Toggle(_ROTATION)] _RotationToggle ("Use Rotation?", Float) = 1
        _RotationSpeed ("Rotation Speed", Float) = 1
        
        [Header(Scale Animation)]
        [Toggle(_SCALE)] _ScaleToggle ("Use Scale Animation?", Float) = 1
        _ScaleFloor ("Scale Floor", Float) = 0.4
        _ScaleCeiling ("Scale Ceiling", Float) = 1
        _ScaleSpeed ("Scale Speed", Float) = 1

        [Header(Sprite Overlay)]
        [Toggle(_SPRITES)] _SpriteToggle ("Use Sprite Overlay?", Float) = 0
        _SpriteTex ("Spritesheet (RGBA)", 2D) = "black" {}
        _SpriteRows("Rows", Float) = 0
		_SpriteColumns("Columns", Float) = 0
		_SpriteTotalTiles("TotalTiles", Float) = 0
		_SpriteSpeed("Speed", Float) = 0    
    }
    SubShader {
        Tags {
            "RenderType"="TransparentCutout"
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
            #include "AutoLight.cginc"
            #pragma multi_compile_fwdbase_fullshadows
            #pragma only_renderers d3d9 d3d11 glcore gles 
            #pragma multi_compile __ _SCALE
            #pragma multi_compile __ _ROTATION
            #pragma multi_compile __ _SPRITES
            #pragma target 3.0
            uniform float4 _Color;
            uniform sampler2D _MainTex; uniform float4 _MainTex_ST;
            uniform sampler2D _EmissionMap; uniform float4 _EmissionMap_ST;
            uniform float _Emission;
            uniform sampler2D _NormalMap; uniform float4 _NormalMap_ST;
            uniform float _Intensity;
            float3 Function_node_3693( float3 normal ){
            return ShadeSH9(half4(normal, 1.0));
            
            }
            
            uniform float4 _StaticToonLight;
            uniform sampler2D _Ramp; uniform float4 _Ramp_ST;
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
            
            uniform float _Saturation;
            uniform fixed _BillboardStaticLight;
            uniform float _ToonContrast;
            float _RotationSpeed;
            float _ScaleFloor;
            float _ScaleCeiling;
            float _ScaleSpeed;
            sampler2D _SpriteTex; float4 _SpriteTex_ST;
            float _SpriteColumns;
            float _SpriteRows;
            float _SpriteSpeed;
            float _SpriteTotalTiles;
            
            float2 gifUV (float Speed, float2 UV, float2 Tiles, float TileCount) {
                float frame = floor(fmod(_Time.y * Speed, TileCount));
                float column = fmod(frame, Tiles.x);
                float row = fmod(frame-column, Tiles.y);
                float2 offset = float2(row, column);
                return (UV+offset) / Tiles;
            }

            struct VertexInput {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float2 uv : TEXCOORD0;
            };
            struct VertexOutput {
                float4 pos : SV_POSITION;
                float2 uv0 : TEXCOORD0;
                float2 uv1 : TEXCOORD7;
                float4 posWorld : TEXCOORD1;
                float3 normalDir : TEXCOORD2;
                float3 tangentDir : TEXCOORD3;
                float3 bitangentDir : TEXCOORD4;
                LIGHTING_COORDS(5,6)
            };
            VertexOutput vert (VertexInput v) {
                VertexOutput o = (VertexOutput)0;
                o.uv1 = v.uv;
                v.uv.xy -= 0.5;

                #if _SCALE
                // float2x2 scaleMatrix = _ScaleFloor.xxxx;
                // v.uv.xy = mul(v.uv.xy, scaleMatrix);
                v.uv.xy *= lerp(_ScaleCeiling, _ScaleFloor, sin(_Time.y * _ScaleSpeed)+1/2);
                #endif

                #if _ROTATION
				float sinX = sin ( _RotationSpeed * _Time );
				float cosX = cos ( _RotationSpeed * _Time );
				float sinY = sin ( _RotationSpeed * _Time );
				float2x2 rotationMatrix = float2x2( cosX, -sinX, sinY, cosX);
				rotationMatrix *=0.5;
                rotationMatrix +=0.5;
                rotationMatrix = rotationMatrix * 2-1;
				v.uv.xy = mul ( v.uv.xy, rotationMatrix );
                #endif


                v.uv.xy += 0.5;
				o.uv0 = TRANSFORM_TEX(v.uv, _MainTex);
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
                float4 _MainTex_var = tex2D(_MainTex,TRANSFORM_TEX(i.uv0, _MainTex));
                #if defined(_SPRITES)
                float2 gifGrid = float2(_SpriteRows, _SpriteColumns);
                float2 gUV = gifUV(_SpriteSpeed, i.uv1, gifGrid, _SpriteTotalTiles);
                float4 gif = tex2D(_SpriteTex, TRANSFORM_TEX(gUV, _SpriteTex));
                float4 combinedTex = lerp(_MainTex_var, gif, gif.a);
                _MainTex_var = combinedTex;
                #endif
                clip(_MainTex_var.a - 0.5);
                float3 lightColor = _LightColor0.rgb;
////// Lighting:
                float attenuation = LIGHT_ATTENUATION(i) / SHADOW_ATTENUATION(i);
////// Emissive:
                float4 _EmissionMap_var = tex2D(_EmissionMap,TRANSFORM_TEX(i.uv0, _EmissionMap));
                float3 MappedEmissive = (_EmissionMap_var.rgb*_Emission);
                float3 emissive = MappedEmissive;
                float3 FlatLighting = saturate((Function_node_3693( float3(0,1,0) )+(_LightColor0.rgb*attenuation)));
                float3 MappedTexture = (_MainTex_var.rgb*_Color.rgb);
                float3 Diffuse = lerp(lerp(MappedTexture,dot(MappedTexture,float3(0.3,0.59,0.11)),(-0.5)),dot(lerp(MappedTexture,dot(MappedTexture,float3(0.3,0.59,0.11)),(-0.5)),float3(0.3,0.59,0.11)),(1.0 - _Saturation));
                float node_424 = 0.5;
                float node_7394_if_leA = step(_BillboardStaticLight,1.0);
                float node_7394_if_leB = step(1.0,_BillboardStaticLight);
                float3 VRPosition = VRViewPosition();
                float3 node_3406 = (i.posWorld.rgb-VRPosition);
                float3 node_1153 = (-1*(node_3406/length(node_3406))).rgb;
                float2 node_7017 = normalize(float2(node_1153.r,node_1153.b));
                float2 node_7930 = node_7017.rg;
                float2 node_8628 = (float2((-1*node_7930.g),node_7930.r)*(-1*_StaticToonLight.r)).rg;
                float2 node_3851 = (node_7017*_StaticToonLight.b).rg;
                float3 StaticLightDirection = lerp((node_7394_if_leA*_StaticToonLight.rgb)+(node_7394_if_leB*_StaticToonLight.rgb),(float3(node_8628.r,_StaticToonLight.g,node_8628.g)+float3(node_3851.r,_StaticToonLight.g,node_3851.g)),node_7394_if_leA*node_7394_if_leB);
                float node_1617 = 0.5*dot((normalDirection*faceSign),StaticLightDirection)+0.5;
                float2 node_8091 = float2(node_1617,node_1617);
                float4 node_9498 = tex2D(_Ramp,TRANSFORM_TEX(node_8091, _Ramp));
                float3 StaticToonLighting = node_9498.rgb;
                float3 finalColor = emissive + saturate(((_Intensity*FlatLighting*Diffuse) > 0.5 ?  (1.0-(1.0-2.0*((_Intensity*FlatLighting*Diffuse)-0.5))*(1.0-lerp(float3(node_424,node_424,node_424),StaticToonLighting,_ToonContrast))) : (2.0*(_Intensity*FlatLighting*Diffuse)*lerp(float3(node_424,node_424,node_424),StaticToonLighting,_ToonContrast))) );
                
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
            #include "AutoLight.cginc"
            #pragma multi_compile_fwdadd_fullshadows
            #pragma only_renderers d3d9 d3d11 glcore gles 
            #pragma multi_compile __ _SCALE
            #pragma multi_compile __ _ROTATION
            #pragma multi_compile __ _SPRITES
            #pragma target 3.0
            uniform float4 _Color;
            uniform sampler2D _MainTex; uniform float4 _MainTex_ST;
            uniform sampler2D _EmissionMap; uniform float4 _EmissionMap_ST;
            uniform float _Emission;
            uniform sampler2D _NormalMap; uniform float4 _NormalMap_ST;
            uniform float _Intensity;
            float2 gifUV (float Speed, float2 UV, float2 Tiles, float TileCount) {
                float frame = floor(fmod(_Time.y * Speed, TileCount));
                float column = fmod(frame, Tiles.x);
                float row = fmod(frame-column, Tiles.y);
                float2 offset = float2(row, column);
                return (UV+offset) / Tiles;
            }
            float3 Function_node_3693( float3 normal ){
            return ShadeSH9(half4(normal, 1.0));
            
            }
            
            uniform float4 _StaticToonLight;
            uniform sampler2D _Ramp; uniform float4 _Ramp_ST;
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
            
            uniform float _Saturation;
            uniform fixed _BillboardStaticLight;
            uniform float _ToonContrast;
            float _RotationSpeed;
            float _ScaleFloor;
            float _ScaleCeiling;
            float _ScaleSpeed;
            sampler2D _SpriteTex; float4 _SpriteTex_ST;
            float _SpriteColumns;
            float _SpriteRows;
            float _SpriteSpeed;
            float _SpriteTotalTiles;

            struct VertexInput {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float2 uv : TEXCOORD0;
            };
            struct VertexOutput {
                float4 pos : SV_POSITION;
                float2 uv0 : TEXCOORD0;
                float2 uv1 : TEXCOORD7;

                float4 posWorld : TEXCOORD1;
                float3 normalDir : TEXCOORD2;
                float3 tangentDir : TEXCOORD3;
                float3 bitangentDir : TEXCOORD4;
                LIGHTING_COORDS(5,6)
            };
            VertexOutput vert (VertexInput v) {
                VertexOutput o = (VertexOutput)0;
                o.uv1 = v.uv;
                v.uv.xy -= 0.5;

                #if defined(_SCALE)
                // float2x2 scaleMatrix = _ScaleFloor.xxxx;
                // v.uv.xy = mul(v.uv.xy, scaleMatrix);
                v.uv.xy *= lerp(_ScaleCeiling, _ScaleFloor, sin(_Time.y * _ScaleSpeed)+1/2);
                #endif

                #if defined(_ROTATION)
				float sinX = sin ( _RotationSpeed * _Time );
				float cosX = cos ( _RotationSpeed * _Time );
				float sinY = sin ( _RotationSpeed * _Time );
				float2x2 rotationMatrix = float2x2( cosX, -sinX, sinY, cosX);
				rotationMatrix *=0.5;
                rotationMatrix +=0.5;
                rotationMatrix = rotationMatrix * 2-1;
				v.uv.xy = mul ( v.uv.xy, rotationMatrix );
                #endif



                v.uv.xy += 0.5;
				o.uv0 = TRANSFORM_TEX(v.uv, _MainTex);
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
                float4 _MainTex_var = tex2D(_MainTex,TRANSFORM_TEX(i.uv0, _MainTex));
                #if defined(_SPRITES)
                float2 gifGrid = float2(_SpriteRows, _SpriteColumns);
                float2 gUV = gifUV(_SpriteSpeed, i.uv1, gifGrid, _SpriteTotalTiles);
                float4 gif = tex2D(_SpriteTex, TRANSFORM_TEX(gUV, _SpriteTex));
                float4 combinedTex = lerp(_MainTex_var, gif, gif.a);
                _MainTex_var = combinedTex;
                #endif
                clip(_MainTex_var.a - 0.5);
                float3 lightColor = _LightColor0.rgb;
////// Lighting:
                float attenuation = LIGHT_ATTENUATION(i) / SHADOW_ATTENUATION(i);
                float3 FlatLighting = saturate((Function_node_3693( float3(0,1,0) )+(_LightColor0.rgb*attenuation)));
                float3 MappedTexture = (_MainTex_var.rgb*_Color.rgb);
                float3 Diffuse = lerp(lerp(MappedTexture,dot(MappedTexture,float3(0.3,0.59,0.11)),(-0.5)),dot(lerp(MappedTexture,dot(MappedTexture,float3(0.3,0.59,0.11)),(-0.5)),float3(0.3,0.59,0.11)),(1.0 - _Saturation));
                float node_424 = 0.5;
                float node_7394_if_leA = step(_BillboardStaticLight,1.0);
                float node_7394_if_leB = step(1.0,_BillboardStaticLight);
                float3 VRPosition = VRViewPosition();
                float3 node_3406 = (i.posWorld.rgb-VRPosition);
                float3 node_1153 = (-1*(node_3406/length(node_3406))).rgb;
                float2 node_7017 = normalize(float2(node_1153.r,node_1153.b));
                float2 node_7930 = node_7017.rg;
                float2 node_8628 = (float2((-1*node_7930.g),node_7930.r)*(-1*_StaticToonLight.r)).rg;
                float2 node_3851 = (node_7017*_StaticToonLight.b).rg;
                float3 StaticLightDirection = lerp((node_7394_if_leA*_StaticToonLight.rgb)+(node_7394_if_leB*_StaticToonLight.rgb),(float3(node_8628.r,_StaticToonLight.g,node_8628.g)+float3(node_3851.r,_StaticToonLight.g,node_3851.g)),node_7394_if_leA*node_7394_if_leB);
                float node_1617 = 0.5*dot((normalDirection*faceSign),StaticLightDirection)+0.5;
                float2 node_8091 = float2(node_1617,node_1617);
                float4 node_9498 = tex2D(_Ramp,TRANSFORM_TEX(node_8091, _Ramp));
                float3 StaticToonLighting = node_9498.rgb;
                float3 finalColor = saturate(((_Intensity*FlatLighting*Diffuse) > 0.5 ?  (1.0-(1.0-2.0*((_Intensity*FlatLighting*Diffuse)-0.5))*(1.0-lerp(float3(node_424,node_424,node_424),StaticToonLighting,_ToonContrast))) : (2.0*(_Intensity*FlatLighting*Diffuse)*lerp(float3(node_424,node_424,node_424),StaticToonLighting,_ToonContrast))) );
                return fixed4(finalColor * 1,0);
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
            #include "AutoLight.cginc"
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
                float3 MappedEmissive = (_EmissionMap_var.rgb*_Emission);
                o.Emission = MappedEmissive;
                
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
