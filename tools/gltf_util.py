"""Kleine Hilfsfunktionen zum Lesen und Schreiben von glTF-Dateien (ohne Fremdbibliotheken außer numpy)."""
import json
import os
import struct

import numpy as np

COMP = {5120: np.int8, 5121: np.uint8, 5122: np.int16, 5123: np.uint16, 5125: np.uint32, 5126: np.float32}
NCOMP = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4, "MAT4": 16}


class Gltf:
    def __init__(self, path):
        self.path = path
        self.dir = os.path.dirname(path)
        data = open(path, "rb").read()
        if data[:4] == b"glTF":
            jlen = struct.unpack("<I", data[12:16])[0]
            self.j = json.loads(data[20:20 + jlen])
            off = 20 + jlen
            blen = struct.unpack("<I", data[off:off + 4])[0]
            self.bins = [data[off + 8:off + 8 + blen]]
        else:
            self.j = json.loads(data)
            self.bins = [open(os.path.join(self.dir, b["uri"]), "rb").read() for b in self.j["buffers"]]

    def node(self, name):
        for i, n in enumerate(self.j["nodes"]):
            if n.get("name") == name:
                return i
        raise KeyError(name)

    def acc(self, idx):
        a = self.j["accessors"][idx]
        bv = self.j["bufferViews"][a["bufferView"]]
        dt = np.dtype(COMP[a["componentType"]])
        n = NCOMP[a["type"]]
        start = bv.get("byteOffset", 0) + a.get("byteOffset", 0)
        stride = bv.get("byteStride", 0)
        buf = self.bins[bv["buffer"]]
        if stride and stride != dt.itemsize * n:
            raw = np.frombuffer(buf, np.uint8, count=stride * a["count"], offset=start).reshape(a["count"], stride)
            arr = raw[:, :dt.itemsize * n].copy().view(dt)
        else:
            arr = np.frombuffer(buf, dt, count=a["count"] * n, offset=start).copy()
        arr = arr.reshape(a["count"], n) if n > 1 else arr
        if a["type"] == "MAT4":
            arr = arr.reshape(-1, 4, 4)
        if a.get("normalized") and dt != np.float32:
            arr = arr.astype(np.float32) / np.iinfo(dt).max
        return arr


class Writer:
    """Baut eine neue glTF-Datei mit einem einzigen .bin-Puffer auf."""

    def __init__(self):
        self.j = {"asset": {"version": "2.0", "generator": "Dungeon Break tools"}, "scenes": [{"nodes": []}], "scene": 0,
                  "nodes": [], "meshes": [], "accessors": [], "bufferViews": [], "materials": [], "textures": [],
                  "images": [], "samplers": [{"magFilter": 9729, "minFilter": 9987}], "skins": [], "animations": []}
        self.blob = bytearray()

    def add(self, arr, target=None, minmax=False, normalized=False):
        arr = np.ascontiguousarray(arr)
        ctype = {np.dtype(v): k for k, v in COMP.items()}[arr.dtype]
        if arr.ndim == 3:
            typ, count = "MAT4", arr.shape[0]
        else:
            n = 1 if arr.ndim == 1 else arr.shape[1]
            typ, count = {1: "SCALAR", 2: "VEC2", 3: "VEC3", 4: "VEC4"}[n], arr.shape[0]
        while len(self.blob) % 4:
            self.blob.append(0)
        bv = {"buffer": 0, "byteOffset": len(self.blob), "byteLength": arr.nbytes}
        if target:
            bv["target"] = target
        self.blob += arr.tobytes()
        self.j["bufferViews"].append(bv)
        a = {"bufferView": len(self.j["bufferViews"]) - 1, "componentType": ctype, "count": count, "type": typ}
        if normalized:
            a["normalized"] = True
        if minmax:
            flat = arr.reshape(count, -1)
            a["min"] = flat.min(0).tolist()
            a["max"] = flat.max(0).tolist()
        self.j["accessors"].append(a)
        return len(self.j["accessors"]) - 1

    def add_node(self, node, root=False):
        self.j["nodes"].append(node)
        i = len(self.j["nodes"]) - 1
        if root:
            self.j["scenes"][0]["nodes"].append(i)
        return i

    def save(self, path):
        base = os.path.splitext(os.path.basename(path))[0]
        self.j["buffers"] = [{"uri": base + ".bin", "byteLength": len(self.blob)}]
        for k in [k for k, v in self.j.items() if v == []]:
            del self.j[k]
        with open(path, "w") as f:
            json.dump(self.j, f, separators=(",", ":"))
        with open(os.path.join(os.path.dirname(path), base + ".bin"), "wb") as f:
            f.write(self.blob)
