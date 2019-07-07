using System;
using UnityEngine;
using System.Collections;
using DefaultNamespace;
using UnityEngine.Rendering;
using UnityEngine.Rendering.PostProcessing;

[RequireComponent(typeof(Camera))]
public class RayMarchingControls : MonoBehaviour
{
    public PostProcessVolume volume;

    private float fogHue;

    private void Awake()
    {
        var settings = volume.profile.GetSetting<RayMarchingEffect>();

        var originalColor = settings.FogColor.value;
        float oH, oS, oV;
        Color.RGBToHSV(originalColor, out oH, out oS, out oV);

        fogHue = oH;
    }

    private void OnGUI()
    {
        var settings = volume.profile.GetSetting<RayMarchingEffect>();

        GUILayout.Space(12);
		GUILayout.Label(new GUIContent("Hue"));

        var originalColor = settings.FogColor.value;
        float oH,oS,oV;
        Color.RGBToHSV(originalColor, out oH, out oS, out oV);

        fogHue = GUILayout.HorizontalSlider(fogHue, 0, 1,GUILayout.Width(120));
        settings.FogColor.Override(Color.HSVToRGB(fogHue, oS, oV));
    }
}
