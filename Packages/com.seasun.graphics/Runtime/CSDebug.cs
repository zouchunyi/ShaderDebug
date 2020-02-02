using System;
using System.IO;
using System.Text;
using System.Collections.Generic;
#if UNITY_EDITOR
using UnityEditor;
#endif
using UnityEngine;

namespace CoreFramework.GraphicsTools
{
    public static class CSDebug
    {
        /* ---------------------------------------------- */
        /* ComputeShader Debug */
#if UNITY_EDITOR
        private readonly static string WITH_MACROS_FILE =
            Application.dataPath + "/../Packages/com.seasun.graphics/Shaders/Debug/CSDebug/CSDebugWithMacros.hlsl";
        private readonly static string WITHOUT_MACROS_FILE =
            Application.dataPath + "/../Packages/com.seasun.graphics/Shaders/Debug/CSDebug/CSDebugWithoutMacros.hlsl";
        private readonly static string CURRENT_FILE =
            Application.dataPath + "/../Packages/com.seasun.graphics/Shaders/Debug/CSDebug.hlsl";

        private static string GetFileMD5(string file)
        {
            try
            {
                Byte[] bytes = File.ReadAllBytes(file);
                System.Security.Cryptography.MD5 md5 = new System.Security.Cryptography.MD5CryptoServiceProvider();
                byte[] retVal = md5.ComputeHash(bytes);

                StringBuilder sb = new StringBuilder();
                for (int i = 0; i < retVal.Length; i++)
                {
                    sb.Append(retVal[i].ToString("x2"));
                }
                return sb.ToString();
            }
            catch (Exception ex)
            {
                throw new Exception("md5file() fail, error:" + ex.Message);
            }
        }
#endif

        private static void ExcuteMacros()
        {
#if UNITY_EDITOR
            string curMD5 = GetFileMD5(CURRENT_FILE);
#if CS_DEBUG
            string targetMD5 = GetFileMD5(WITH_MACROS_FILE);
            if (!curMD5.Equals(targetMD5))
            {
                File.Copy(WITH_MACROS_FILE, CURRENT_FILE, true);
                AssetDatabase.Refresh();
            }
#else
            string targetMD5 = GetFileMD5(WITHOUT_MACROS_FILE);
            if (!curMD5.Equals(targetMD5))
            {
                File.Copy(WITHOUT_MACROS_FILE, CURRENT_FILE, true);
                AssetDatabase.Refresh();
            }
#endif
#endif
        }

#if CS_DEBUG
        private static Dictionary<string, ComputeBuffer> m_DebugBufferDict = new Dictionary<string, ComputeBuffer>();
#endif

        public static void ComputeShaderDebugSet(string key, ComputeShader computeShader, int kernal)
        {
            ExcuteMacros();
#if CS_DEBUG
            ComputeBuffer buffer = null;
            if (!m_DebugBufferDict.TryGetValue(key, out buffer))
            {
                buffer = new ComputeBuffer(1, 4);
                buffer.SetData(new float[]{0});
                m_DebugBufferDict.Add(key, buffer);
            }
            computeShader.SetBuffer(kernal, Shader.PropertyToID(key), buffer);
#endif
        }

        public static float ComputeShaderDebugGet(string key)
        {
            ExcuteMacros();
#if CS_DEBUG
            ComputeBuffer buffer = null;
            if (m_DebugBufferDict.TryGetValue(key, out buffer))
            {
                float[] values = new float[1] {0};
                buffer.GetData(values);
                return values[0];
            }
#endif
            return 0;
        }

        public static void ComputeShaderDebugRelease()
        {
            ExcuteMacros();
#if CS_DEBUG
            foreach (var computeBuffer in m_DebugBufferDict.Values)
            {
                if (computeBuffer != null)
                {
                    computeBuffer.Release();
                }
            }
            m_DebugBufferDict.Clear();
#endif
        }
    }
}


