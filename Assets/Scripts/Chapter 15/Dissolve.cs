using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Dissolve : MonoBehaviour
{
    public Material material;

    [Range(0.01f , 1.0f)]
    public float burnSpeed = 0.1f;
    [Range(0.0f , 1.0f)]
    public float burnAmout = 0.0f;

    void start()
    {
        if(material == null)
        {
            Renderer renderer = gameObject.GetComponentInChildren<Renderer>();
            if(renderer != null)
            {
                material = renderer.material;
            }
        }

        if(material == null)
        {
            this.enabled = false;
        }
        else
        {
            material.SetFloat("_BurnAmount" , 0.0f);
        }
    }

    void Update()
    {
        burnAmout = Mathf.Repeat(Time.time * burnSpeed , 1.0f);
        material.SetFloat("_BurnAmount" , burnAmout);
    }
}
