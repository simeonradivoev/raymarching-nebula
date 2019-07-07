using System;
using UnityEngine;
using UnityEngine.Rendering.PostProcessing;

namespace DefaultNamespace
{
    [Serializable]
    public class LightParameter : ParameterOverride<Light> { }

    [Serializable]
    [PostProcess(typeof(RayMarchingEffectRenderer), PostProcessEvent.BeforeStack, "Custom/Ray Marching")]
    public class RayMarchingEffect : PostProcessEffectSettings
    {
        public Vector3Parameter Center = new Vector3Parameter();
        [Header("Noise")]
        public TextureParameter NoiseTexture = new TextureParameter(){defaultState = TextureParameterDefault.White};
        public TextureParameter NoiseOffsets = new TextureParameter(){defaultState = TextureParameterDefault.White};
        public FloatParameter NoiseSize = new FloatParameter(){value = 1};
        [Range(0, 1)]
        public FloatParameter NoiseAmount = new FloatParameter(){value = 1};
        [Header("Fog")]
        public ColorParameter FogColor = new ColorParameter(){value = Color.white };
        [Range(0, 1)]
        public FloatParameter FogStauration =new FloatParameter(){value = 0.58f };
        private FloatParameter FogHue = new FloatParameter(){value = 0.08f };
        public FloatParameter MaxViewDistance = new FloatParameter(){value = 200 };
        public IntParameter Iterations = new IntParameter(){value = 100 };
        public FloatParameter FalloffPower = new FloatParameter(){value = 1.2f };
        public FloatParameter ScatteringCoeff = new FloatParameter(){value = 0.25f };
        public FloatParameter ExtinctionCoeff = new FloatParameter(){value = 0.01f };
        public FloatParameter DepthThreshold = new FloatParameter(){value = 0.01f };
        public FloatParameter Density = new FloatParameter(){value = 0.5f };
        [Range(1, 12)]
        public IntParameter downsample = new IntParameter(){value = 1};
    }

    public class RayMarchingEffectRenderer : PostProcessEffectRenderer<RayMarchingEffect>
    {
        #region Overrides of PostProcessEffectRenderer

        public override void Render(PostProcessRenderContext context)
        {
            RenderTextureFormat formatRF32 = RenderTextureFormat.RFloat;
            int lowresDepthWidth = context.width / 2;
            int lowresDepthHeight = context.height / 2;

            var downscaleDepthSheet = context.propertySheets.Get(Shader.Find("Hidden/Downscale Depth"));
            var lowresDepthRT = Shader.PropertyToID("_LowResDepth");
            context.command.GetTemporaryRT(lowresDepthRT, lowresDepthWidth, lowresDepthHeight, 4,FilterMode.Point, formatRF32);
            context.command.BlitFullscreenTriangle(context.source, lowresDepthRT, downscaleDepthSheet,0);

            context.command.SetGlobalTexture("LowResDepthTexture", lowresDepthRT);

            context.command.SetGlobalMatrix("InverseViewMatrix", context.camera.cameraToWorldMatrix);
            context.command.SetGlobalMatrix("InverseProjectionMatrix", context.camera.projectionMatrix.inverse);

            var sheet = context.propertySheets.Get(Shader.Find("Hidden/Raymarch"));

            sheet.properties.SetColor("FogColor", settings.FogColor);
            sheet.properties.SetFloat("NoiseAmount", settings.NoiseAmount);
            sheet.properties.SetFloat("NoiseSize", settings.NoiseSize);
            sheet.properties.SetTexture("NoiseTexture", settings.NoiseTexture.value ? settings.NoiseTexture.value : Texture2D.whiteTexture);
            sheet.properties.SetTexture("_NoiseOffsets", settings.NoiseOffsets.value ? settings.NoiseOffsets.value : Texture2D.whiteTexture);
            sheet.properties.SetInt("_Iterations", settings.Iterations);
            sheet.properties.SetVector("LightPos", settings.Center);
            sheet.properties.SetFloat("ScatteringCoeff", settings.ScatteringCoeff);
            sheet.properties.SetFloat("ExtinctionCoeff", settings.ExtinctionCoeff);
            sheet.properties.SetFloat("Density", settings.Density);
            sheet.properties.SetFloat("MaxViewDistance", settings.MaxViewDistance);
            sheet.properties.SetFloat("FalloffPower", settings.FalloffPower);

            var rt = Shader.PropertyToID("_RT");
            context.command.GetTemporaryRT(rt,context.width / settings.downsample, context.height / settings.downsample, 0,FilterMode.Bilinear, RenderTextureFormat.ARGBFloat);
            context.command.BlitFullscreenTriangle(rt, rt, sheet,0);

            var combineSheet = context.propertySheets.Get(Shader.Find("Hidden/Raymarch Combine"));
            combineSheet.properties.SetFloat("DepthThreshold", settings.DepthThreshold);
            context.command.SetGlobalTexture("LowResDepthTexture", lowresDepthRT);
            context.command.SetGlobalTexture("_Clouds", rt);

            context.command.BlitFullscreenTriangle(context.source, context.destination, combineSheet,0);

            context.command.ReleaseTemporaryRT(rt);
            context.command.ReleaseTemporaryRT(lowresDepthRT);
        }

        #endregion
    }
}