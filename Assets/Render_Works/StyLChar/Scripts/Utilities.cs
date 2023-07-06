using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

namespace NormalSmootherGUI
{
    public class Utilities
    {
        public static void MakeTitle(string tile)
        {
            EditorGUILayout.LabelField(tile, EditorStyles.miniButton);
        }
        
        public static void MakeSubCell(string subTitle, string message = null)
        {
            // define the font of sub titles
            GUIStyle style01 = new GUIStyle("label");
            style01.alignment = TextAnchor.MiddleLeft;
            style01.wordWrap = false;
            style01.fontStyle = FontStyle.Bold;
            style01.fontSize = NormalSmoother.FONTSIZE;

            // define the font of illustrations
            GUIStyle style02 = new GUIStyle("label");
            style02.wordWrap = true;
            style02.richText = true;
            style02.fontSize = NormalSmoother.FONTSIZE - 6;

            EditorGUILayout.BeginVertical(new GUIStyle("Box"));
            if (subTitle != "")
                EditorGUILayout.TextArea(subTitle, style01);
            EditorGUILayout.TextArea(message, style02);
            EditorGUILayout.EndVertical();
        }

        public static bool MakeButton(string buttonText, float width, float height)
        {
            bool mBool = GUILayout.Button(buttonText, GUILayout.Width(width), GUILayout.Height(height));
            return mBool;
        }
    }
}