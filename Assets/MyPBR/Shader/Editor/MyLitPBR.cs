using System;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEditor.Rendering.Universal;

namespace UnityEditor.Rendering.Universal.ShaderGUI
{
    internal class MyLitPBR : BaseShaderGUI
    {
        // Properties
        private MyPBRGUI.LitProperties litProperties; 

        private bool foldutC1 = true;
        private bool foldutC2 = true;
        private bool foldutC3 = true;
        private bool foldutC4 = true;

        protected class StStyles       
        {
            public static readonly GUIContent SurfaceOptions =
                EditorGUIUtility.TrTextContent("Fundamental Properties", "Controls how URP Renders the material on screen.");

            public static readonly GUIContent CustomProps =
                EditorGUIUtility.TrTextContent("Custom Properties", "Customize the lighting and rendering logics.");

            public static readonly GUIContent stylizedDiffuseGUI = new GUIContent("Stylized Diffuse",
                "These settings describe the look and feel of the surface itself.");

            // Catergories
            public static readonly GUIContent ARTTexGUI = new GUIContent ("Art Texture ",
                "To Stylized the material surface. R - Medium, G - Shadow, B - Reflect. ");

            public static readonly GUIContent medColorGUI = new GUIContent("Medium Color",
                "These settings describe the look and feel of the surface itself.");

            public static readonly GUIContent medThresholdGUI = new GUIContent("Medium Threshold",
                "These settings describe the look and feel of the surface itself.");

            public static readonly GUIContent medSmoothGUI = new GUIContent("Medium Smooth",
                "These settings describe the look and feel of the surface itself.");

            public static readonly GUIContent medArtTexStrengthGUI = new GUIContent("Medium ArtTex Strength",
                "These settings describe the look and feel of the surface itself.");

            public static readonly GUIContent shadowColorGUI = new GUIContent("Shadow Color",
                "These settings describe the look and feel of the surface itself.");

            public static readonly GUIContent shadowThresholdGUI = new GUIContent("Shadow Threshold",
                "These settings describe the look and feel of the surface itself.");

            public static readonly GUIContent shadowSmoothGUI = new GUIContent("Shadow Smooth",
                "These settings describe the look and feel of the surface itself.");

            public static readonly GUIContent shadowArtTexStrengthGUI = new GUIContent("Shadow ArtTex Strength",
                "These settings describe the look and feel of the surface itself.");

            public static readonly GUIContent reflColorGUI = new GUIContent("Reflect Color",
                "These settings describe the look and feel of the surface itself.");

            public static readonly GUIContent reflThresholdGUI = new GUIContent("Reflect Threshold",
                "These settings describe the look and feel of the surface itself.");

            public static readonly GUIContent reflSmoothGUI = new GUIContent("Reflect Smooth",
                "These settings describe the look and feel of the surface itself.");

            public static readonly GUIContent reflArtTexStrengthGUI = new GUIContent("Reflect ArtTex Strength",
                "These settings describe the look and feel of the surface itself.");

            public static readonly GUIContent giIntensityGUI = new GUIContent("GI (indirect Diffuse) Intensity",
                "These settings describe the look and feel of the surface itself.");

            public static readonly GUIContent ggxSpecularGUI = new GUIContent("GGX Specular",
                "These settings describe the look and feel of the surface itself.");

            public static readonly GUIContent specularLightOffsetGUI = new GUIContent("Specular Light Offset",
                "These settings describe the look and feel of the surface itself.");

            public static readonly GUIContent specularThresholdGUI = new GUIContent("Specular Threshold",
                "These settings describe the look and feel of the surface itself.");

            public static readonly GUIContent specularSmoothGUI = new GUIContent("Specular Smooth",
                "These settings describe the look and feel of the surface itself.");

            public static readonly GUIContent specularIntensityGUI = new GUIContent("Specular Intensity",
                "These settings describe the look and feel of the surface itself.");
            public static readonly GUIContent directionalFresnelGUI = new GUIContent("Directional Fresnel",
                "These settings describe the look and feel of the surface itself.");

            public static readonly GUIContent fresnelThresholdGUI = new GUIContent("Fresnel Threshold",
                "These settings describe the look and feel of the surface itself.");

            public static readonly GUIContent fresnelSmoothGUI = new GUIContent("Fresnel Smooth",
                "These settings describe the look and feel of the surface itself.");

            public static readonly GUIContent fresnelIntensityGUI = new GUIContent("Fresnel Intensity",
                "These settings describe the look and feel of the surface itself.");

            public static readonly GUIContent reflProbeIntensityGUI = new GUIContent("Non Metal Reflection Probe Intensity",
                "These settings describe the look and feel of the surface itself.");

            public static readonly GUIContent metalReflProbeIntensityGUI = new GUIContent("Metal Reflection Probe Intensity",
                "These settings describe the look and feel of the surface itself.");

            // collect properties from the material properties
        }

        
        public override void OnGUI(MaterialEditor materialEditorIn, MaterialProperty[] properties)
        {
            if (materialEditorIn == null)
                throw new ArgumentNullException("materialEditorIn");

            materialEditor = materialEditorIn;
            Material material = materialEditor.target as Material;
            
            EditorGUI.BeginChangeCheck();

            FindProperties(properties);   // MaterialProperties can be animated so we do not cache them but fetch them every event to ensure animated values are updated correctly

            // Make sure that needed setup (ie keywords/renderqueue) are set up if we're switching some existing
            // material to a universal shader.
            if (m_FirstTimeApply)
            {
                OnOpenGUI(material, materialEditorIn);
                m_FirstTimeApply = false;
            }

            ShaderPropertiesGUI(material);

            if (EditorGUI.EndChangeCheck())
            {
                MyPBRGUI.UpdateSurfaceType(material);
            }
        }


        protected virtual uint materialFilter => uint.MaxValue;
        MaterialHeaderScopeList m_MaterialScopeList = new MaterialHeaderScopeList(uint.MaxValue & ~(uint)Expandable.Advanced);


        public override void OnOpenGUI(Material material, MaterialEditor materialEditor)
        {
            var filter = (Expandable)materialFilter;

            // Generate the foldouts
            if (filter.HasFlag(Expandable.SurfaceOptions))
                m_MaterialScopeList.RegisterHeaderScope(StStyles.SurfaceOptions, (uint)Expandable.SurfaceOptions, DrawSurfaceOptions);

            if (filter.HasFlag(Expandable.SurfaceInputs))
                m_MaterialScopeList.RegisterHeaderScope(Styles.SurfaceInputs, (uint)Expandable.SurfaceInputs, DrawSurfaceInputs);

            //if (filter.HasFlag(Expandable.Details)) FillAdditionalFoldouts(m_MaterialScopeList);

            if (filter.HasFlag(Expandable.Advanced))
                m_MaterialScopeList.RegisterHeaderScope(StStyles.CustomProps, (uint)Expandable.Advanced, DrawAdvancedOptions);
        }


        public void ShaderPropertiesGUI(Material material)
        {
            m_MaterialScopeList.DrawHeaders(materialEditor, material);
        }

        public override void FindProperties(MaterialProperty[] properties)
        {
            base.FindProperties(properties);
            litProperties = new MyPBRGUI.LitProperties(properties);
        }

        // material changed check
        public override void MaterialChanged(Material material)
        {
            if (material == null)
                throw new ArgumentNullException("material");

            SetMaterialKeywords(material, MyPBRGUI.SetMaterialKeywords);        
        }

        // material main surface options
        public override void DrawSurfaceOptions(Material material)
        {
            if (material == null)
                throw new ArgumentNullException("material");

            // Use default labelWidth
            EditorGUIUtility.labelWidth = 0f;

            // Detect any changes to the material
            EditorGUI.BeginChangeCheck();
            if (litProperties.workflowMode != null)
            {
                DoPopup(MyPBRGUI.Styles.workflowModeText, litProperties.workflowMode, Enum.GetNames(typeof(MyPBRGUI.WorkflowMode)));
            }
            if (EditorGUI.EndChangeCheck())
            {
                foreach (var obj in blendModeProp.targets)
                    MaterialChanged((Material)obj);
            }
            base.DrawSurfaceOptions(material);
        }

        public void DrawStylizedInputs(Material material) // main custom functions
        {
            
            if (litProperties.artTex != null ) // Draw the baseMap, most shader will have at least a baseMap
            {
                //EditorGUILayout.HelpBox("Art Texture", MessageType.None);
                foldutC1 = EditorGUILayout.Foldout(foldutC1, "Art Texture Settings");
                if (foldutC1)
                {
                    EditorGUILayout.Space();
                    materialEditor.TexturePropertySingleLine(StStyles.ARTTexGUI, litProperties.artTex); 
                    // TODO Temporary fix for lightmapping, to be replaced with attribute tag.
                    if (material.HasProperty("_ArtTex"))
                    {
                        material.SetTexture("_ArtTex", litProperties.artTex.textureValue);
                        
                        var artTexTiling = litProperties.artTex.textureScaleAndOffset;
                        material.SetTextureScale("_ArtTex", new Vector2(artTexTiling.x, artTexTiling.y));
                        material.SetTextureOffset("_ArtTex", new Vector2(artTexTiling.z, artTexTiling.w));
                    }
                    if (material.GetTexture("_ArtTex") != null)
                    {
                        materialEditor.TextureScaleOffsetProperty(litProperties.artTex);
                        materialEditor.ShaderProperty(litProperties.medArtTexStrength, StStyles.medArtTexStrengthGUI, 2);
                        materialEditor.ShaderProperty(litProperties.shadowArtTexStrength, StStyles.shadowArtTexStrengthGUI, 2);
                        materialEditor.ShaderProperty(litProperties.reflArtTexStrength, StStyles.reflArtTexStrengthGUI, 2);
                    }
                }
                //EditorGUILayout.EndFoldoutHeaderGroup();

                EditorGUILayout.Space();

                foldutC2 = EditorGUILayout.Foldout(foldutC2, "Duffuse Settings");
                if (foldutC2)
                {
                    materialEditor.ShaderProperty(litProperties.medColor, StStyles.medColorGUI, 1);
                    materialEditor.ShaderProperty(litProperties.medThreshold, StStyles.medThresholdGUI, 1);
                    materialEditor.ShaderProperty(litProperties.medSmooth, StStyles.medSmoothGUI, 1);
                    

                    materialEditor.ShaderProperty(litProperties.shadowColor, StStyles.shadowColorGUI, 1);
                    materialEditor.ShaderProperty(litProperties.shadowThreshold, StStyles.shadowThresholdGUI, 1);
                    materialEditor.ShaderProperty(litProperties.shadowSmooth, StStyles.shadowSmoothGUI, 1);

                    materialEditor.ShaderProperty(litProperties.reflColor, StStyles.reflColorGUI, 1);
                    materialEditor.ShaderProperty(litProperties.reflThreshold, StStyles.reflThresholdGUI, 1);
                    materialEditor.ShaderProperty(litProperties.reflSmooth, StStyles.reflSmoothGUI, 1);

                    EditorGUILayout.Space();
                    materialEditor.ShaderProperty(litProperties.giIntensity, StStyles.giIntensityGUI, 1);

                }
                //EditorGUILayout.EndFoldoutHeaderGroup();

                EditorGUILayout.Space();

                foldutC3 = EditorGUILayout.Foldout(foldutC3, "Reflection Settings");
                if (foldutC3)
                {
                    materialEditor.ShaderProperty(litProperties.ggxSpecular, StStyles.ggxSpecularGUI, 1);
                    materialEditor.ShaderProperty(litProperties.specularLightOffset, StStyles.specularLightOffsetGUI, 1);
                    if (material.GetFloat("_GGXSpecular") == 0)
                    {
                        materialEditor.ShaderProperty(litProperties.specularThreshold, StStyles.specularThresholdGUI, 1);
                        materialEditor.ShaderProperty(litProperties.specularSmooth, StStyles.specularSmoothGUI, 1);
                    }
                    materialEditor.ShaderProperty(litProperties.specularIntensity, StStyles.specularIntensityGUI, 1);

                    materialEditor.ShaderProperty(litProperties.directionalFresnel, StStyles.directionalFresnelGUI, 1);
                    materialEditor.ShaderProperty(litProperties.fresnelThreshold, StStyles.fresnelThresholdGUI, 1);
                    materialEditor.ShaderProperty(litProperties.fresnelSmooth, StStyles.fresnelSmoothGUI, 1);
                    materialEditor.ShaderProperty(litProperties.fresnelIntensity, StStyles.fresnelIntensityGUI, 1);
                
                    EditorGUILayout.Space(10);

                    materialEditor.ShaderProperty(litProperties.reflProbeIntensity, StStyles.reflProbeIntensityGUI, 1);
                    materialEditor.ShaderProperty(litProperties.metalReflProbeIntensity, StStyles.metalReflProbeIntensityGUI, 1);
                }

                //EditorGUILayout.EndFoldoutHeaderGroup();
            }
        }

        // material main surface inputs
        public override void DrawSurfaceInputs(Material material)
        {
            base.DrawSurfaceInputs(material);
            MyPBRGUI.Inputs(litProperties, materialEditor, material);
           
            DrawEmissionProperties(material, true);
            DrawTileOffset(materialEditor, baseMapProp);
        }


        private void DrawEmissionTextureProperty()
        {
            if ((emissionMapProp == null) || (emissionColorProp == null))
                return;

            using (new EditorGUI.IndentLevelScope(2))
            {
                materialEditor.TexturePropertyWithHDRColor(Styles.emissionMap, emissionMapProp, emissionColorProp, false);
            }
        }

        protected override void DrawEmissionProperties(Material material, bool keyword)
        {
            var emissive = true;

            if (!keyword)
            {
                DrawEmissionTextureProperty();
            }
            else
            {
                emissive = materialEditor.EmissionEnabledProperty();
                using (new EditorGUI.DisabledScope(!emissive))
                {
                    DrawEmissionTextureProperty();
                }
            }

            CoreUtils.SetKeyword(material, "_EMISSION", emissive);

            // If texture was assigned and color was black set color to white
            if ((emissionMapProp != null) && (emissionColorProp != null))
            {
                var hadEmissionTexture = emissionMapProp?.textureValue != null;
                var brightness = emissionColorProp.colorValue.maxColorComponent;
                if (emissionMapProp.textureValue != null && !hadEmissionTexture && brightness <= 0f)
                    emissionColorProp.colorValue = Color.white;
            }

            if (emissive)
            {
                // Change the GI emission flag and fix it up with emissive as black if necessary.
                materialEditor.LightmapEmissionFlagsProperty(MaterialEditor.kMiniTextureFieldLabelIndentLevel, true);
            }
                
        }


        // material main advanced options
        public override void DrawAdvancedOptions(Material material)
        {

            //Stylized Lit
            EditorGUILayout.Space();
            EditorGUI.BeginChangeCheck();
            DrawStylizedInputs(material);
            EditorGUILayout.Space();

            foldutC4 = EditorGUILayout.Foldout(foldutC4, "Other Settings");
            if (foldutC4)
            {
                if (litProperties.reflections != null && litProperties.highlights != null)
                {
                    materialEditor.ShaderProperty(litProperties.highlights, MyPBRGUI.Styles.highlightsText);
                    materialEditor.ShaderProperty(litProperties.reflections, MyPBRGUI.Styles.reflectionsText);
                }

                if(EditorGUI.EndChangeCheck())
                {
                    MaterialChanged(material);
                }
                base.DrawAdvancedOptions(material);
            }

            //EditorGUILayout.EndFoldoutHeaderGroup();
        }

        public override void AssignNewShaderToMaterial(Material material, Shader oldShader, Shader newShader)
        {
            if (material == null)
                throw new ArgumentNullException("material");

            // _Emission property is lost after assigning Standard shader to the material
            // thus transfer it before assigning the new shader
            if (material.HasProperty("_Emission"))
            {
                material.SetColor("_EmissionColor", material.GetColor("_Emission"));
            }

            base.AssignNewShaderToMaterial(material, oldShader, newShader);

            if (oldShader == null || !oldShader.name.Contains("Legacy Shaders/"))
            {
                SetupMaterialBlendMode(material);
                return;
            }

            SurfaceType surfaceType = SurfaceType.Opaque;
            BlendMode blendMode = BlendMode.Alpha;
            if (oldShader.name.Contains("/Transparent/Cutout/"))
            {
                surfaceType = SurfaceType.Opaque;
                material.SetFloat("_AlphaClip", 1);
            }
            else if (oldShader.name.Contains("/Transparent/"))
            {
                // NOTE: legacy shaders did not provide physically based transparency
                // therefore Fade mode
                surfaceType = SurfaceType.Transparent;
                blendMode = BlendMode.Alpha;
            }
            material.SetFloat("_Surface", (float)surfaceType);
            material.SetFloat("_Blend", (float)blendMode);

            if (oldShader.name.Equals("Standard (Specular setup)"))
            {
                material.SetFloat("_WorkflowMode", (float)MyPBRGUI.WorkflowMode.Specular);
                Texture texture = material.GetTexture("_SpecGlossMap");
                if (texture != null)
                    material.SetTexture("_MetallicSpecGlossMap", texture);
            }
            else
            {
                material.SetFloat("_WorkflowMode", (float)MyPBRGUI.WorkflowMode.Metallic);
                Texture texture = material.GetTexture("_MetallicGlossMap");
                if (texture != null)
                    material.SetTexture("_MetallicSpecGlossMap", texture);
            }

            MaterialChanged(material);
        }
    }
}
