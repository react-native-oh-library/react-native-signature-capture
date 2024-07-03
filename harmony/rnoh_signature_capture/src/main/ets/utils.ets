/**
 * MIT License
 *
 * Copyright (C) 2024 Huawei Device Co., Ltd.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

import fs, { ReadOptions } from '@ohos.file.fs';

/*
 * 流式读写 使用系统fs.copyFile会报错
 *
 * @param source 原文件沙箱路径
 * @param dest 目标沙箱路径
 */
async function copyFile(source: string, dest: string): Promise<void> {
  // 打开文件流
  let inputStream = fs.createStreamSync(source, 'r+');
  let outputStream = fs.createStreamSync(dest, "w+");
  // 以流的形式读取源文件内容并写入目的文件
  let bufSize = 4096;
  let readSize = 0;
  let buf = new ArrayBuffer(bufSize);
  let readOptions: ReadOptions = {
    offset: readSize,
    length: bufSize
  };
  let readLen = await inputStream.read(buf, readOptions);
  readSize += readLen;
  while (readLen > 0) {
    await outputStream.write(buf);
    readOptions.offset = readSize;
    readLen = await inputStream.read(buf, readOptions);
    readSize += readLen;
  }
  // 关闭文件流
  inputStream.closeSync();
  outputStream.closeSync();
}