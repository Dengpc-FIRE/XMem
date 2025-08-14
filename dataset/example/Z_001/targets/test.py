import SimpleITK as sitk
import numpy as np

def count_objects_in_mha(mha_path):
    img = sitk.ReadImage(mha_path)
    arr = sitk.GetArrayFromImage(img)  # (frames, H, W)

    print(f"标签数据形状: {arr.shape}")

    for i in range(arr.shape[0]):
        frame = arr[i]
        unique_labels = np.unique(frame)
        # 通常背景标签是0，不计入物体数
        object_labels = unique_labels[unique_labels != 0]
        print(f"第{i+1}帧中不同物体数量（不含背景0）：{len(object_labels)}，标签值: {object_labels}")

if __name__ == "__main__":
    mha_file_path = "Z_001_labels.mha"
    count_objects_in_mha(mha_file_path)
