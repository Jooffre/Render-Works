using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace NormalSmootherGUI
{
    public class Average
    {
        public static void WirteAverageNormalToTangent(GameObject target)
        {
            if (target.GetComponentsInChildren<MeshFilter>().Length != 0)
            {
                MeshFilter[] meshFilters = target.GetComponentsInChildren<MeshFilter>();
                foreach (var meshFilter in meshFilters)
                {
                    Mesh mesh = meshFilter.sharedMesh;
                    WirteAverageNormalToTangent(mesh);
                }
                Debug.Log("Restructure Complete.");
            }

            else if (target.GetComponentsInChildren<SkinnedMeshRenderer>().Length != 0)
            {
                SkinnedMeshRenderer[] skinMeshRenders = target.GetComponentsInChildren<SkinnedMeshRenderer>();
                foreach (var skinMeshRender in skinMeshRenders)
                {
                    Mesh mesh = skinMeshRender.sharedMesh;
                    WirteAverageNormalToTangent(mesh);
                }
                Debug.Log("Restructure Complete.");
            }

            else
                Debug.Log("The Chosen Target Does NOT Contain Any Mesh Information.");
        }

        private static void WirteAverageNormalToTangent(Mesh mesh)
        {
            var averageNormalHash = new Dictionary<Vector3, Vector3>();
            for (var j = 0; j < mesh.vertexCount; j++)
            {
                if (!averageNormalHash.ContainsKey(mesh.vertices[j]))
                {
                    averageNormalHash.Add(mesh.vertices[j], mesh.normals[j]);
                }
                else
                {
                    averageNormalHash[mesh.vertices[j]] =
                        (averageNormalHash[mesh.vertices[j]] + mesh.normals[j]).normalized;
                }
            }

            var averageNormals = new Vector3[mesh.vertexCount];
            for (var j = 0; j < mesh.vertexCount; j++)
            {
                averageNormals[j] = averageNormalHash[mesh.vertices[j]];
            }

            var tangents = new Vector4[mesh.vertexCount];
            for (var j = 0; j < mesh.vertexCount; j++)
            {
                tangents[j] = new Vector4(averageNormals[j].x, averageNormals[j].y, averageNormals[j].z, 0);
            }
            mesh.tangents = tangents;
        }
    }
}
