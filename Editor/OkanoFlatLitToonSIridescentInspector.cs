using UnityEditor;
using UnityEngine;
using System.Collections.Generic;
using System.Linq;
using System;

public class OkanoFlatLitToonSIridescentInspector : ShaderGUI
{
    public enum OutlineMode
    {
        None,
        Tinted,
        Colored
    }

    public enum BlendMode
    {
        Opaque,
        Cutout,
        Fade,   // Old school alpha-blending mode, fresnel does not affect amount of transparency
        Transparent // Physically plausible transparency mode, implemented as alpha pre-multiply
    }

    MaterialProperty blendMode;
    MaterialProperty mainTexture;
    MaterialProperty color;
    MaterialProperty colorMask;
    MaterialProperty lightingRamp;
    MaterialProperty shadow;
    MaterialProperty fresnel;
    MaterialProperty outlineMode;
    MaterialProperty outlineWidth;
    MaterialProperty outlineColor;
    MaterialProperty emissionMap;
    MaterialProperty emissionColor;
    MaterialProperty normalMap;
    MaterialProperty specularMap;
    MaterialProperty specularPow;
    MaterialProperty alphaCutoff;
    MaterialProperty iridescentMap;
    MaterialProperty iridescentMix;
    MaterialProperty iridescentMask;
    MaterialProperty instability;

    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] props)
    {
        { //Find Properties
            blendMode = FindProperty("_Mode", props);
            mainTexture = FindProperty("_MainTex", props);
            color = FindProperty("_Color", props);
            colorMask = FindProperty("_ColorMask", props);
            lightingRamp = FindProperty("_LightingRamp", props);
            shadow = FindProperty("_Shadow", props);
            fresnel = FindProperty("_Fresnel", props);
            outlineMode = FindProperty("_OutlineMode", props);
            outlineWidth = FindProperty("_outline_width", props);
            outlineColor = FindProperty("_outline_color", props);
            emissionMap = FindProperty("_EmissionMap", props);
            emissionColor = FindProperty("_EmissionColor", props);
            specularMap = FindProperty("_SpecularMap", props);
            specularPow = FindProperty("_SpecularPower", props);
            normalMap = FindProperty("_BumpMap", props);
            alphaCutoff = FindProperty("_Cutoff", props);
            iridescentMap = FindProperty("_IridescentMap", props);
            iridescentMask = FindProperty("_IridescentMask", props);
            iridescentMix = FindProperty("_IridescentMix", props);
            instability = FindProperty("_Instability", props);
        }
        
        Material material = materialEditor.target as Material;

        { //Shader Properties GUI
            EditorGUIUtility.labelWidth = 0f;
            
            EditorGUI.BeginChangeCheck();
            {
                EditorGUI.showMixedValue = blendMode.hasMixedValue;
                var bMode = (BlendMode)blendMode.floatValue;

                EditorGUI.BeginChangeCheck();
                bMode = (BlendMode)EditorGUILayout.Popup("Rendering Mode", (int)bMode, Enum.GetNames(typeof(BlendMode)));
                if (EditorGUI.EndChangeCheck())
                {
                    materialEditor.RegisterPropertyChangeUndo("Rendering Mode");
                    blendMode.floatValue = (float)bMode;

                    foreach (var obj in blendMode.targets)
                    {
                        SetupMaterialWithBlendMode((Material)obj, (BlendMode)material.GetFloat("_Mode"));
                    }
                }

                EditorGUI.showMixedValue = false;


                materialEditor.TexturePropertySingleLine(new GUIContent("Main Texture", "Main Color Texture (RGB)"), mainTexture, color);
                EditorGUI.indentLevel += 2;
                if((BlendMode)material.GetFloat("_Mode") == BlendMode.Cutout)
                    materialEditor.ShaderProperty(alphaCutoff, "Alpha Cutoff", 2);
                materialEditor.TexturePropertySingleLine(new GUIContent("Color Mask", "Masks Color Tinting (G)"), colorMask);
                EditorGUI.indentLevel -= 2;
                materialEditor.TexturePropertySingleLine(new GUIContent("Normal Map", "Normal Map (RGB)"), normalMap);
                materialEditor.TexturePropertySingleLine(new GUIContent("Emission", "Emission (RGB)"), emissionMap, emissionColor);
                materialEditor.TexturePropertySingleLine(new GUIContent("Specular Map", "Specular Map (RGB)"), specularMap);
                materialEditor.ShaderProperty(specularPow, "Specular Exponent");
                materialEditor.TexturePropertySingleLine(new GUIContent("Lighting Ramp", "Lighting Ramp (RGB)"), lightingRamp);
                EditorGUI.BeginChangeCheck();
                materialEditor.TextureScaleOffsetProperty(mainTexture);
                if (EditorGUI.EndChangeCheck())
                    emissionMap.textureScaleAndOffset = mainTexture.textureScaleAndOffset;
                
                EditorGUILayout.Space();
                materialEditor.ShaderProperty(shadow, "Shadow");
                materialEditor.ShaderProperty(fresnel, "Fresnel");

                EditorGUILayout.Space();
                materialEditor.TextureProperty(iridescentMap, "Iridescent Cubemap (RGB)", false);
                EditorGUI.indentLevel += 2;
                materialEditor.ShaderProperty(iridescentMix, "Iridescent Mix");
                materialEditor.TexturePropertySingleLine(new GUIContent("Iridescent Mask (G)"), iridescentMask);
                materialEditor.ShaderProperty(instability, "Instability");
                EditorGUI.indentLevel -= 2;
                

                var oMode = (OutlineMode)outlineMode.floatValue;

                EditorGUI.BeginChangeCheck();
                oMode = (OutlineMode)EditorGUILayout.Popup("Outline Mode", (int)oMode, Enum.GetNames(typeof(OutlineMode)));
                
                if (EditorGUI.EndChangeCheck())
                {
                    materialEditor.RegisterPropertyChangeUndo("Outline Mode");
                    outlineMode.floatValue = (float)oMode;

                    foreach (var obj in outlineMode.targets)
                    {
                        SetupMaterialWithOutlineMode((Material)obj, (OutlineMode)material.GetFloat("_OutlineMode"));
                    }

                }
                switch (oMode)
                {
                    case OutlineMode.Tinted:
                    case OutlineMode.Colored:
                        materialEditor.ShaderProperty(outlineColor, "Color", 2);
                        materialEditor.ShaderProperty(outlineWidth, new GUIContent("Width", "Outline Width in cm"), 2);
                        break;
                    case OutlineMode.None:
                    default:
                        break;
                }                
            }
            EditorGUI.EndChangeCheck();
        }

    }

    public static void SetupMaterialWithBlendMode(Material material, BlendMode blendMode)
    {
        switch ((BlendMode)material.GetFloat("_Mode"))
        {
            case BlendMode.Opaque:
                material.SetOverrideTag("RenderType", "");
                material.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.One);
                material.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.Zero);
                material.SetInt("_ZWrite", 1);
                material.DisableKeyword("_ALPHATEST_ON");
                material.DisableKeyword("_ALPHABLEND_ON");
                material.DisableKeyword("_ALPHAPREMULTIPLY_ON");
                material.renderQueue = -1;
                break;
            case BlendMode.Cutout:
                material.SetOverrideTag("RenderType", "TransparentCutout");
                material.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.One);
                material.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.Zero);
                material.SetInt("_ZWrite", 1);
                material.EnableKeyword("_ALPHATEST_ON");
                material.DisableKeyword("_ALPHABLEND_ON");
                material.DisableKeyword("_ALPHAPREMULTIPLY_ON");
                material.renderQueue = (int)UnityEngine.Rendering.RenderQueue.AlphaTest;
                break;
            case BlendMode.Fade:
                material.SetOverrideTag("RenderType", "Transparent");
                material.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.SrcAlpha);
                material.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.OneMinusSrcAlpha);
                material.SetInt("_ZWrite", 0);
                material.DisableKeyword("_ALPHATEST_ON");
                material.EnableKeyword("_ALPHABLEND_ON");
                material.DisableKeyword("_ALPHAPREMULTIPLY_ON");
                material.renderQueue = (int)UnityEngine.Rendering.RenderQueue.Transparent;
                break;
            case BlendMode.Transparent:
                material.SetOverrideTag("RenderType", "Transparent");
                material.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.One);
                material.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.OneMinusSrcAlpha);
                material.SetInt("_ZWrite", 0);
                material.DisableKeyword("_ALPHATEST_ON");
                material.DisableKeyword("_ALPHABLEND_ON");
                material.EnableKeyword("_ALPHAPREMULTIPLY_ON");
                material.renderQueue = (int)UnityEngine.Rendering.RenderQueue.Transparent;
                break;
        }
    }

    public static void SetupMaterialWithOutlineMode(Material material, OutlineMode outlineMode)
    {
        switch ((OutlineMode)material.GetFloat("_OutlineMode"))
        {
            case OutlineMode.None:
                material.EnableKeyword("NO_OUTLINE");
                material.DisableKeyword("TINTED_OUTLINE");
                material.DisableKeyword("COLORED_OUTLINE");
                break;
            case OutlineMode.Tinted:
                material.DisableKeyword("NO_OUTLINE");
                material.EnableKeyword("TINTED_OUTLINE");
                material.DisableKeyword("COLORED_OUTLINE");
                break;
            case OutlineMode.Colored:
                material.DisableKeyword("NO_OUTLINE");
                material.DisableKeyword("TINTED_OUTLINE");
                material.EnableKeyword("COLORED_OUTLINE");
                break;
            default:
                break;
        }
    }
}