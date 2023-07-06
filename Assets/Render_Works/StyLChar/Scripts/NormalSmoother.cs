using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

namespace NormalSmootherGUI
{
    public class NormalSmoother : EditorWindow
    {
        public static int FONTSIZE = 20;
        private bool mMainButton;

        private GameObject target;

        [MenuItem("Custom Tools/Normal Smoother", false, 20)]
        private static void ShowWindow()
        {
            var window = GetWindow<NormalSmoother>();
            window.titleContent = new GUIContent("Normal Smoother");
            window.Show();
        }

        private void OnGUI()
        {
            MakeWorkspace();
        }

        private void MakeWorkspace()
        {
            // =======================================  ReadMe =======================================

            EditorGUILayout.BeginHorizontal();

            Utilities.MakeTitle("· ReadMe ·");

            EditorGUILayout.EndHorizontal();

            ReadMeModule();


            // ========================================  Main ========================================
            
            EditorGUILayout.BeginHorizontal();

            Utilities.MakeTitle("Impletement");

            EditorGUILayout.EndHorizontal();

            MainModule();
            
        }

        private void ReadMeModule()
        {
            EditorGUILayout.BeginHorizontal("Box");

            Utilities.MakeSubCell("", "• This tool is used to handle the broken outline when using a vert-expansion outlining shader.\n \n"
                                    + "• It works by average normals with respect to each vertex of the target, and write the new avg-normals info to the tangent channel. Note this modification will NOT apply to the original model data, it is a temporary cache and will be released everytime you quite Unity.\n\n"
                                    + "• Remember to change the normal channel to TANGENT in your shader after use this tool!");

            EditorGUILayout.EndHorizontal();
        }

        private void MainModule()
        {
            EditorGUILayout.BeginHorizontal("Box");

            EditorGUILayout.BeginVertical();

            Utilities.MakeSubCell("", "Select a FBX model or its sub-component object from the scene.\n");

            target = EditorGUILayout.ObjectField("Select a target", target, typeof(GameObject), true) as GameObject;

            EditorGUILayout.EndVertical();
            
            mMainButton = Utilities.MakeButton("Reconstruct", 160, 64);

            if (mMainButton)
            {
                Average.WirteAverageNormalToTangent(target);
            }

            EditorGUILayout.EndHorizontal();

        }
    }
}
