using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class AutoRotate : MonoBehaviour {

	// Use this for initialization
	void Start () {
		
	}
	
	// Update is called once per frame
	void Update () {
        Vector3 rotate = Vector3.zero;
        rotate.y += Time.deltaTime * 100f;
        transform.Rotate(rotate);
	}
}
