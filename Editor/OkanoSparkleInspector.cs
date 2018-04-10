using UnityEditor;
using UnityEngine;
using System.Collections.Generic;
using System.Linq;
using System;

public class OkanoSparkleInspector : ShaderGUI {

    public enum Filter {
        VividLight,
        HardLight,
        SoftLight,
        PinLight,
        LinearLight
    }

    public static Dictionary<Filter, string> filterMap;

    MaterialProperty sparkleFilter;

    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] props) {
        filterMap = new Dictionary<Filter, string>{
            { Filter.VividLight, "_FILTER_VIVID" },
            { Filter.HardLight, "_FILTER_HARD" },
            { Filter.SoftLight, "_FILTER_SOFT" },
            { Filter.PinLight, "_FILTER_PIN" },
            { Filter.LinearLight, "_FILTER_LINEAR" }
        };

        {
            sparkleFilter = FindProperty("_EmissionFilterMode", props);
        }
        // render the default gui
        base.OnGUI(materialEditor, props);

        Material material = materialEditor.target as Material;

        EditorGUI.BeginChangeCheck();
        var fMode = (Filter)sparkleFilter.floatValue;
        EditorGUIUtility.labelWidth = 0f;
        fMode = (Filter)EditorGUILayout.Popup("Emission Filter Mode", (int)fMode, Enum.GetNames(typeof(Filter)));
        if (EditorGUI.EndChangeCheck()) {
            materialEditor.RegisterPropertyChangeUndo("Emission Filter Mode");
            sparkleFilter.floatValue = (float)fMode;

            foreach (var obj in sparkleFilter.targets) {
                SetupMaterialWithFilterMode((Material)obj, (Filter)material.GetFloat("_EmissionFilterMode"));
            }
        }

        // // see if redify is set, and show a checkbox
        // bool redify = Array.IndexOf(targetMat.shaderKeywords, "REDIFY_ON") != -1;
        // EditorGUI.BeginChangeCheck();
        // redify = EditorGUILayout.Toggle("Redify material", redify);
        // if (EditorGUI.EndChangeCheck())
        // {
        //     // enable or disable the keyword based on checkbox
        //     if (redify)
        //         targetMat.EnableKeyword("REDIFY_ON");
        //     else
        //         targetMat.DisableKeyword("REDIFY_ON");
        // }
    }

    public static void SetupMaterialWithFilterMode(Material material, Filter filterMode) {
        // disable keywords first
        foreach (var opt in filterMap) {
            material.DisableKeyword(opt.Value);
        }

        material.EnableKeyword(filterMap[filterMode]);
    }

}