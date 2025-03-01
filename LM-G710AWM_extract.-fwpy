#!/usr/bin/env python3
# A simple and correct LG KDZ Android image extractor, because I got fed up
# with the partially working one from kdztools.
#
# Copyright (c) 2021 Isaac Garzon
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

"""
Most of this file was written by the author above. However, it did not work 
present day with LM-G710AWM device firmware. I spent hours exploring ways to 
extract the partitions, and individual images to no avail. Within the kdz file 
exists a partition index of sorts, extracted as kdz_extras.bin. Regardless, I 
would never have been able to fully extract the filesystem without the original 
file written by Isaac Garzon. Oiriginal copyright and props to you, your code
is levels above my initial approach however, I don't have solid understanding 
of file formats, versions, which elude to magic numbers, offsets, etc. I just
know how to use binwalk.

The original author set strict assertions with respect to errors. The reality, 
especially given KDZ and DZ files use (depending on their version) compression 
combined with partition indexing as well as padding via null bytes results in 
some 'variety' with respect to strict extraction or reading of partitions. So
when the original author wrote this, it worked for his needs and again - in all
fairness, being strict is not a bad thing. My workaround for LM-G710AWM (and
others) firmware is primarily the result of loosening those restrictions, and
allowing the program to continue running. It will throw some warnings, but I
have verified that it still ultimately extracts what we want. 

In testing eve unkdz from kdztools, it does not properly extract, Or at least
in my experience, its a fractured output, where partitions and images are 
chunked and will not be re assembled properly.

Due to certain KDZs having unusual or partially inconsistent chunk meta
data, I've introduced an option --lenient-chunks. If set, when the script 
encounters a mismatch due to unexpected data found at an offset based on 
LG KDZ file descriptors (V1,V2,or V3),, the assertion error is thrown as
a warning instead, allowing graceful continuation of script execution.

Another commandline option, -l --list, has been added. It will display the
partitions, their names, offsets and sizes. This is effectively the data
required to execute the extraction.

Lastly, by using -l, you can determine the partition names, and substitute
a comma separated list of partition names you want to extract if you do 
not wish to extract all partitions/images.


This script extracts Android system images from an LG KDZ file. It supports:
 - Reading and parsing the KDZ file header (which may be version 1, 2, or 3).
 - Optionally reading a "secure partition" structure at a configurable offset/size/magic.
 - Finding and parsing the internal .dz file, which contains multiple partition chunks
   that may be compressed (zlib or zstd).
 - Extracting the resulting partitions to disk, or listing them in a --list mode.

NEW FIX: LENIENT CHUNK PARSING
==============================
Due to certain KDZs having unusual or partially inconsistent chunk metadata,
we introduce an option `--lenient-chunks`. If set, when the script encounters
a mismatch in `maybe_pstart_sector` (i.e., the typical "Mismatch part start sector" 
AssertionError), it will log a warning and continue by forcing the chunk to 
use the script’s computed `part_start_sector`.


KBS      < admin[AT]dtrh[DOT]net >
         < https://dtrh.net    >
         < Feb 29, 2025      >

"""


from __future__ import print_function
import argparse
import binascii
import collections
import datetime
import errno
import hashlib
import io
import os
import struct
import zlib
import zstandard


def decode_asciiz(s):
    """
    Decodes a byte string `s` as ASCII, removing trailing null (0x00).
    Used for KDZ or DZ fields that are null-terminated ASCII.
    """
    return s.rstrip(b'\x00').decode('ascii')


def iter_read(file, size, chunk_size):
    """
    Reads exactly 'size' bytes from 'file' in increments of 'chunk_size'.
    Ensures no unexpected EOF (chunk=0).
    """
    while size > 0:
        chunk = file.read(min(chunk_size, size))
        assert len(chunk) > 0, "Unexpected EOF while reading data"
        yield chunk
        size -= len(chunk)


class KdzHeader(object):
    """
    Represents an LG KDZ header. 
    The KDZ can be v1, v2, or v3, which differ in size + magic + record layout.
    """

    V1_HDR_SIZE = 1304
    V2_HDR_SIZE = 1320
    V3_HDR_SIZE = 1320

    V1_MAGIC = 0x50447932
    V2_MAGIC = 0x80253134
    V3_MAGIC = 0x25223824

    BASE_HDR_FMT = struct.Struct('<II')  # size, magic

    # v1: <256sII> repeated for 2 records (DZ, DLL)
    V1_RECORD_FMT = struct.Struct('<256sII')
    V1_RECORDS = (V1_RECORD_FMT, V1_RECORD_FMT)

    # v2: <256sQQ> repeated for 2 records, then 1B, then 2 more <256sQQ>
    V2_RECORD_FMT = struct.Struct('<256sQQ')
    V2_RECORDS = (
        V2_RECORD_FMT, V2_RECORD_FMT,
        struct.Struct('<B'),
        V2_RECORD_FMT, V2_RECORD_FMT
    )

    # v3: basically v2 + more fields for suffix map, etc.
    V3_ADDITIONAL_RECORD_FMT = struct.Struct('<QI')  # offset(Q), size(I)
    V3_RECORDS = (
        V2_RECORD_FMT, V2_RECORD_FMT,
        struct.Struct('<B'),
        V2_RECORD_FMT, V2_RECORD_FMT,
        struct.Struct('<I5s'),    # extended_mem_id_size, tag
        struct.Struct('<Q'),      # total size of additional records
        V3_ADDITIONAL_RECORD_FMT, # suffix map
        V3_ADDITIONAL_RECORD_FMT, # sku map
        struct.Struct('<32s'),    # ftm_model_name
        V3_ADDITIONAL_RECORD_FMT  # extended sku map
    )

    EXTENDED_MEM_ID_OFFSET = 0x14738

    Record = collections.namedtuple('Record', 'name size offset')
    AdditionalRecord = collections.namedtuple('AdditionalRecord', 'offset size')

    def __init__(self, file, forced_version=None):
        # read enough bytes for the largest header
        raw_header = file.read(self.V3_HDR_SIZE)
        self.forced_version = forced_version

        if forced_version in (1,2,3):
            self._force_parse_version(file, raw_header, forced_version)
        else:
            # auto-detect
            size, magic = self.BASE_HDR_FMT.unpack(raw_header[:self.BASE_HDR_FMT.size])
            self._auto_parse_version(file, raw_header, size, magic)

    def _force_parse_version(self, file, raw_header, forced_version):
        if forced_version == 1:
            self._parse_v1_header(raw_header[:self.V1_HDR_SIZE])
            self.magic = self.V1_MAGIC
            self.size = self.V1_HDR_SIZE
            self.version = 1
        elif forced_version == 2:
            self._parse_v2_header(raw_header[:self.V2_HDR_SIZE])
            self.magic = self.V2_MAGIC
            self.size = self.V2_HDR_SIZE
            self.version = 2
        elif forced_version == 3:
            self._parse_v3_header(raw_header[:self.V3_HDR_SIZE])
            self.magic = self.V3_MAGIC
            self.size = self.V3_HDR_SIZE
            self.version = 3
        else:
            raise ValueError(f"Unknown forced_version {forced_version}")

    def _auto_parse_version(self, file, raw_header, size, magic):
        if size == self.V3_HDR_SIZE and magic == self.V3_MAGIC:
            self._parse_v3_header(raw_header[:self.V3_HDR_SIZE])
            self.magic = magic
            self.size = size
            self.version = 3
        elif size == self.V2_HDR_SIZE and magic == self.V2_MAGIC:
            self._parse_v2_header(raw_header[:self.V2_HDR_SIZE])
            self.magic = magic
            self.size = size
            self.version = 2
        elif size == self.V1_HDR_SIZE and magic == self.V1_MAGIC:
            self._parse_v1_header(raw_header[:self.V1_HDR_SIZE])
            self.magic = magic
            self.size = size
            self.version = 1
        else:
            raise ValueError(
                f"Unknown KDZ header (size={size}, magic=0x{magic:X}). "
                f"Cannot parse as v1, v2, or v3."
            )

    def _parse_v1_header(self, data):
        record_data = io.BytesIO(data[self.BASE_HDR_FMT.size:])
        records = []
        for i, unpacker in enumerate(self.V1_RECORDS):
            raw = record_data.read(unpacker.size)
            name, sz, off = unpacker.unpack(raw)
            name = decode_asciiz(name)
            assert name, f"Empty name in v1 record {i}"
            records.append(self.Record(name, sz, off))

        assert all(b==0 for b in record_data.read()), "Non-zero padding in v1 header"
        self.records = records

        # placeholders for v2/v3
        self.tag = ''
        self.ftm_model_name = ''
        self.additional_records_size = 0
        self.extended_mem_id = self.AdditionalRecord(0,0)
        self.suffix_map = self.AdditionalRecord(0,0)
        self.sku_map = self.AdditionalRecord(0,0)
        self.extended_sku_map = self.AdditionalRecord(0,0)

    def _parse_v2_header(self, data):
        record_data = io.BytesIO(data[self.BASE_HDR_FMT.size:])
        parsed_records = []
        for unpacker in self.V2_RECORDS:
            raw = record_data.read(unpacker.size)
            parsed_records.append(unpacker.unpack(raw))

        assert all(b==0 for b in record_data.read()), "Non-zero padding in v2 header"

        # single byte in the 3rd entry
        assert parsed_records[2][0] in (0,3), f"Unexpected single byte: 0x{parsed_records[2][0]:X}"
        del parsed_records[2]

        records = []
        for (name, sz, off) in parsed_records:
            name = decode_asciiz(name)
            if not name:
                assert sz==0 and off==0, "Unnamed v2 record with non-zero size/offset"
                continue
            records.append(self.Record(name, sz, off))

        self.records = records

        # placeholders for v3
        self.tag = ''
        self.ftm_model_name = ''
        self.additional_records_size = 0
        self.extended_mem_id = self.AdditionalRecord(0,0)
        self.suffix_map = self.AdditionalRecord(0,0)
        self.sku_map = self.AdditionalRecord(0,0)
        self.extended_sku_map = self.AdditionalRecord(0,0)

    def _parse_v3_header(self, data):
        record_data = io.BytesIO(data[self.BASE_HDR_FMT.size:])
        parsed_records = []
        for unpacker in self.V3_RECORDS:
            raw = record_data.read(unpacker.size)
            parsed_records.append(unpacker.unpack(raw))

        assert all(b==0 for b in record_data.read()), "Non-zero padding in v3 header"

        # single byte check
        assert parsed_records[2][0] in (0,3), f"Unexpected byte after DLL record: 0x{parsed_records[2][0]:X}"
        del parsed_records[2]

        # first 4 are normal records
        records = []
        for (nm, sz, off) in parsed_records[:4]:
            name = decode_asciiz(nm)
            if not name:
                assert sz==0 and off==0, "v3 record has empty name but non-zero fields"
                continue
            records.append(self.Record(name, sz, off))

        self.records = records

        # the rest are additional
        additional_records = parsed_records[4:]
        (extended_mem_id_size, tag_bytes) = additional_records[0]
        self.tag = tag_bytes.rstrip(b'\x00').decode('utf-8')
        (self.additional_records_size,) = additional_records[1]

        self.extended_mem_id = self.AdditionalRecord(
            self.EXTENDED_MEM_ID_OFFSET,
            extended_mem_id_size
        )
        self.suffix_map = self.AdditionalRecord(*additional_records[2])
        self.sku_map = self.AdditionalRecord(*additional_records[3])
        (ftm_bytes,) = additional_records[4]
        self.ftm_model_name = ftm_bytes.rstrip(b'\x00').decode('utf-8')
        self.extended_sku_map = self.AdditionalRecord(*additional_records[5])

        sum_maps = (
            self.suffix_map.size +
            self.sku_map.size +
            self.extended_sku_map.size
        )
        assert self.additional_records_size==sum_maps, (
            f"Mismatch in v3 additional records size: "
            f"{self.additional_records_size} != {sum_maps}"
        )


class SecurePartition(object):
    """
    Represents a "secure partition" structure found in some KDZ files.
    We allow overriding offset/size/magic with command-line flags.
    By default:
      offset=1320, size=82448, magic=0x53430799
    """

    DEFAULT_OFFSET = 1320
    DEFAULT_SIZE   = 82448
    DEFAULT_MAGIC  = 0x53430799

    SIG_SIZE_MAX = 0x200
    HDR_FMT = struct.Struct('<IIII{}s'.format(SIG_SIZE_MAX))
    PART_FMT = struct.Struct('<30sBBIIII32s')

    Part = collections.namedtuple(
        'Part', 'name hw_part logical_part start_sect end_sect data_sect_cnt reserved hash'
    )

    def __init__(self, file, offset=None, size=None, magic=None):
        self.offset = offset if offset is not None else self.DEFAULT_OFFSET
        self.size   = size   if size   is not None else self.DEFAULT_SIZE
        self.expected_magic = magic if magic is not None else self.DEFAULT_MAGIC

        file.seek(self.offset)
        data = file.read(self.size)
        if len(data)<self.HDR_FMT.size:
            raise ValueError("Not enough bytes to parse secure partition header")

        magic_val, flags, part_count, sig_size, signature = self.HDR_FMT.unpack(
            data[:self.HDR_FMT.size]
        )

        if magic_val!=self.expected_magic:
            raise ValueError(
                f"SecurePartition: Magic mismatch (got=0x{magic_val:X}, "
                f"expected=0x{self.expected_magic:X}), offset={self.offset}"
            )

        if sig_size>self.SIG_SIZE_MAX:
            raise ValueError(f"Signature too large ({sig_size} bytes)")
        if any(x!=0 for x in signature[sig_size:]):
            raise ValueError("Non-zero bytes in signature padding")

        part_data = data[self.HDR_FMT.size:]
        total_part_size = part_count * self.PART_FMT.size
        if total_part_size>len(part_data):
            raise ValueError(
                f"part_count {part_count} overflows secure partition region "
                f"(need {total_part_size}, have {len(part_data)})"
            )

        remainder_start = total_part_size
        if any(b!=0 for b in part_data[remainder_start:]):
            raise ValueError("Non-zero padding after secure partition entries")

        self.parts = collections.OrderedDict()

        for i, raw in enumerate(self.PART_FMT.iter_unpack(part_data[:remainder_start])):
            (raw_name, hw_part, logical_part, start_sect, end_sect, ds_cnt, res, part_hash) = raw
            name = decode_asciiz(raw_name)
            if ds_cnt==0:
                raise ValueError(f"Partition {name} has data_sect_cnt=0")

            p = self.Part(name, hw_part, logical_part, start_sect, end_sect, ds_cnt, res, part_hash)
            self.parts.setdefault(hw_part, collections.OrderedDict()).setdefault(name, []).append(p)

        self.magic      = magic_val
        self.flags      = flags
        self.signature  = signature[:sig_size]
        self.part_count = part_count
        self.sig_size   = sig_size


class DzHeader(object):
    """
    Represents the .dz file inside a KDZ. 
    We handle chunk headers (v0 or v1) and do zlib/zstd decompression.

    NEW FIX: lenient_chunks:
      If True, we skip the "Mismatch part start sector" assertion 
      and instead log a warning, forcing 'maybe_pstart_sector' to 
      match our computed part_start_sector. Helps if the .dz is 
      slightly inconsistent.
    """

    MAGIC = 0x74189632
    PART_MAGIC = 0x78951230
    READ_CHUNK_SIZE = 1 << 20  # 1MB
    HW_PARTITION_NONE = 0x5000

    HDR_FMT = struct.Struct(
        '<IIII'
        '32s'
        '128s'
        'HHHHHHHH'
        'I'
        '16s'
        'B'
        '9s'
        '16s'
        '50s'
        '16s'
        'I'
        'I'
        '10s'
        '11s'
        '4s'
        'I'
        'I'
        '64s'
        '24s'
        'B'
        'B'
        'I'
        'B'
        '24s'
        'I'
        '44s'
    )

    V0_PART_FMT = struct.Struct(
        '<I'
        '32s'
        '64s'
        'I'
        'I'
        '16s'
    )

    V1_PART_FMT = struct.Struct(
        '<I'      # magic
        '32s'     # part_name
        '64s'     # chunk_name
        'I'       # data_size
        'I'       # file_size
        '16s'     # part_hash
        'I'       # start_sector
        'I'       # sector_count
        'I'       # hw_partition
        'I'       # part_crc
        'I'       # unique_part_id
        'I'       # is_sparse
        'I'       # is_ubi_image
        'I'       # part_start_sector
        '356s'    # padding
    )

    Chunk = collections.namedtuple(
        'Chunk',
        'name data_size file_offset file_size hash crc '
        'start_sector sector_count part_start_sector unique_part_id '
        'is_sparse is_ubi_image'
    )

    def __init__(self, file, lenient_chunks=False):
        """
        :param file: file-like 
        :param lenient_chunks: if True, we skip the mismatch sector assertion in v1.
        """
        self.lenient_chunks = lenient_chunks

        header_data = file.read(self.HDR_FMT.size)
        parsed = self.HDR_FMT.unpack(header_data)

        (magic, major, minor, reserved,
         model_name, sw_version,
         y, m, wd, d, hh, mm, ss, ms,
         part_count, chunk_hdrs_hash, secure_image_type, compression,
         data_hash, swfv, build_type, unk0, header_crc,
         android_ver, memory_size, signed_security,
         is_ufs, anti_rollback_ver,
         supported_mem, target_product,
         multi_panel_mask, product_fuse_id, unk1,
         is_factory_image, operator_code, unk2, padding) = parsed

        # checks
        assert magic==self.MAGIC, f"Invalid .dz magic: 0x{magic:X}"
        assert major<=2 and minor<=1, f"Unexpected .dz version {major}.{minor}"
        assert reserved==0, "reserved != 0"
        assert part_count>0, f"part_count={part_count} invalid"
        assert unk0==0, f"Unknown field not zero: {unk0}"
        assert unk1 in (0,0xffffffff), f"Unexpected value in unknown field: 0x{unk1:X}"
        assert unk2 in (0,1), f"Expected 0 or 1, got {unk2}"
        assert all(x==0 for x in padding), "Non-zero .dz header padding"

        # header CRC
        if header_crc!=0:
            test_data = bytearray(self.HDR_FMT.pack(
                magic, major, minor, reserved,
                model_name, sw_version,
                y, m, wd, d, hh, mm, ss, ms,
                part_count, chunk_hdrs_hash, secure_image_type, compression,
                b'', swfv, build_type, unk0, 0,
                android_ver, memory_size, signed_security,
                is_ufs, anti_rollback_ver,
                supported_mem, target_product,
                multi_panel_mask, product_fuse_id, unk1,
                is_factory_image, operator_code, unk2, padding
            ))
            calc_crc = binascii.crc32(test_data)
            assert header_crc==calc_crc, (
                f".dz header CRC mismatch: got 0x{calc_crc:X}, expected 0x{header_crc:X}"
            )

        # data hash check
        if data_hash!=b'\xff'*16:
            self._verify_data_hash = hashlib.md5(self.HDR_FMT.pack(
                magic, major, minor, reserved,
                model_name, sw_version,
                y, m, wd, d, hh, mm, ss, ms,
                part_count, chunk_hdrs_hash, secure_image_type, compression,
                b'\xff'*16, swfv, build_type, unk0, header_crc,
                android_ver, memory_size, signed_security,
                is_ufs, anti_rollback_ver,
                supported_mem, target_product,
                multi_panel_mask, product_fuse_id, unk1,
                is_factory_image, operator_code, unk2, padding
            ))
        else:
            self._verify_data_hash = None

        # parse build date if not zero
        if not all(v==0 for v in [y,m,wd,d,hh,mm,ss,ms]):
            build_date = datetime.datetime(y,m,d,hh,mm,ss,ms*1000)
            assert build_date.weekday()==wd, "Weekday mismatch in .dz build date"
        else:
            build_date = None

        self.magic = magic
        self.major = major
        self.minor = minor
        self.build_date = build_date
        self.secure_image_type = secure_image_type
        self.swfv = decode_asciiz(swfv)
        self.build_type = decode_asciiz(build_type)
        self.android_ver = decode_asciiz(android_ver)
        self.memory_size = decode_asciiz(memory_size)
        self.signed_security = decode_asciiz(signed_security)
        self.anti_rollback_ver = anti_rollback_ver
        self.supported_mem = decode_asciiz(supported_mem)
        self.target_product = decode_asciiz(target_product)
        self.operator_code = decode_asciiz(operator_code).split('.')
        self.multi_panel_mask = multi_panel_mask
        self.product_fuse_id = product_fuse_id
        self.is_factory_image = (is_factory_image == b'F')
        self.is_ufs = bool(is_ufs)
        self.chunk_hdrs_hash = chunk_hdrs_hash
        self.data_hash = data_hash
        self.header_crc = header_crc
        self.compression = self._interpret_compression(compression)

        if minor==0:
            self.parts = self._parse_v0_part_headers(file, part_count)
        else:
            self.parts = self._parse_v1_part_headers(file, part_count)

        # finalize data MD5
        if self._verify_data_hash:
            calc_md5 = self._verify_data_hash.digest()
            assert calc_md5==data_hash, (
                f".dz data MD5 mismatch: got {binascii.hexlify(calc_md5)}, "
                f"expected {binascii.hexlify(data_hash)}"
            )

    def _interpret_compression(self, compression):
        if compression[1]!=0:
            # treat as ASCII
            comp_str = decode_asciiz(compression).lower()
            assert comp_str in ("zlib","zstd"), f"Unknown compression {comp_str}"
            return comp_str
        else:
            # single-byte code
            code = compression[0]
            assert code in (1,4), f"Unknown compression code {code}"
            return "zlib" if code==1 else "zstd"

    def _parse_v0_part_headers(self, file, part_count):
        parts = collections.OrderedDict()
        hdr_hash = hashlib.md5()
        hw_partition = self.HW_PARTITION_NONE

        for i in range(part_count):
            chunk_hdr_data = file.read(self.V0_PART_FMT.size)
            (magic, pn, cn, data_size, file_size, part_hash) = self.V0_PART_FMT.unpack(chunk_hdr_data)
            hdr_hash.update(chunk_hdr_data)

            assert magic==self.PART_MAGIC, f"Invalid part magic 0x{magic:X} in v0 at idx {i}"
            assert data_size>0 and file_size>0, f"Zero sizes in chunk {i}"

            part_name = decode_asciiz(pn)
            chunk_name= decode_asciiz(cn)
            offset    = file.tell()

            chunk = self.Chunk(
                chunk_name, data_size, offset, file_size,
                part_hash, 0, 0, 0, 0, 0, False, False
            )
            parts.setdefault(hw_partition, collections.OrderedDict())\
                 .setdefault(part_name, []).append(chunk)

            if self._verify_data_hash:
                self._verify_data_hash.update(chunk_hdr_data)
                for chunk_data in iter_read(file, file_size, self.READ_CHUNK_SIZE):
                    self._verify_data_hash.update(chunk_data)
            else:
                file.seek(file_size,1)

        calc_hash = hdr_hash.digest()
        if calc_hash!=self.chunk_hdrs_hash:
            raise ValueError(
                f".dz v0 chunk headers hash mismatch: got {binascii.hexlify(calc_hash)}, "
                f"expected {binascii.hexlify(self.chunk_hdrs_hash)}"
            )
        return parts

    def _parse_v1_part_headers(self, file, part_count):
        """
        v1 part header includes start_sector, sector_count, hw_partition, 
        maybe_pstart_sector, etc. We allow skipping an assertion if 
        --lenient-chunks is used.
        """
        parts = collections.OrderedDict()
        hdr_hash = hashlib.md5()

        part_start_sector = 0
        part_sector_count = 0

        for i in range(part_count):
            chunk_hdr_data = file.read(self.V1_PART_FMT.size)
            (magic, pn, cn,
             data_size, file_size, part_hash,
             start_sector, sector_count, hw_partition,
             part_crc, unique_part_id, is_sparse, is_ubi_image,
             maybe_pstart_sector, pad) = self.V1_PART_FMT.unpack(chunk_hdr_data)

            hdr_hash.update(chunk_hdr_data)

            assert magic==self.PART_MAGIC, f"Invalid part magic 0x{magic:X} in v1 at index {i}"
            assert data_size>0 and file_size>0, f"Zero data/file sizes in chunk {i}"
            assert all(x==0 for x in pad), f"Non-zero padding in chunk header index {i}"

            part_name  = decode_asciiz(pn)
            chunk_name = decode_asciiz(cn)
            offset     = file.tell()

            # If new hw partition
            if hw_partition not in parts:
                part_start_sector = 0
                part_sector_count = 0
                if (maybe_pstart_sector>part_start_sector<=start_sector):
                    part_start_sector = maybe_pstart_sector
            elif part_name not in parts[hw_partition]:
                # new partition name
                if maybe_pstart_sector==0:
                    part_start_sector = start_sector
                else:
                    part_start_sector += part_sector_count
                    if (maybe_pstart_sector>part_start_sector<=start_sector):
                        part_start_sector = maybe_pstart_sector
                part_sector_count = 0

            # The typical assertion:
            if not (maybe_pstart_sector==0 or maybe_pstart_sector==part_start_sector):
                if self.lenient_chunks:
                    print(f"[!] Warning: Mismatch part start sector chunk {i}, "
                          f"forcing maybe_pstart_sector={part_start_sector}")
                    # forcibly correct it
                    maybe_pstart_sector = part_start_sector
                else:
                    raise AssertionError(
                        f"Mismatch part start sector chunk {i} (maybe_pstart_sector={maybe_pstart_sector}, "
                        f"expected={part_start_sector}). Use --lenient-chunks to skip."
                    )

            # build the chunk
            chunk = self.Chunk(
                chunk_name, data_size, offset, file_size, part_hash, part_crc,
                start_sector, sector_count, part_start_sector,
                unique_part_id, bool(is_sparse), bool(is_ubi_image)
            )

            parts.setdefault(hw_partition, collections.OrderedDict())\
                 .setdefault(part_name, []).append(chunk)

            part_sector_count = (start_sector - part_start_sector)+sector_count

            if self._verify_data_hash:
                self._verify_data_hash.update(chunk_hdr_data)
                for chunk_data in iter_read(file, file_size, self.READ_CHUNK_SIZE):
                    self._verify_data_hash.update(chunk_data)
            else:
                file.seek(file_size,1)

        calc_hash = hdr_hash.digest()
        if calc_hash!=self.chunk_hdrs_hash:
            raise ValueError(
                f".dz v1 chunk headers hash mismatch: got {binascii.hexlify(calc_hash)}, "
                f"expected {binascii.hexlify(self.chunk_hdrs_hash)}"
            )
        return parts


def parse_kdz_header(f, forced_version=None):
    """
    Parse the KDZ header from file 'f'. If forced_version in (1,2,3), parse that specifically.
    Prints discovered info about the KDZ.
    """
    hdr = KdzHeader(f, forced_version=forced_version)
    print("KDZ Header")
    print("==========")
    print(f"Detected version: {hdr.version} (forced_version={forced_version})")
    print(f"size = {hdr.size}, magic=0x{hdr.magic:X}")
    print(f"records = {len(hdr.records)}")
    for r in hdr.records:
        print(f"  {r}")
    print(f"tag = {hdr.tag}")
    print(f"extended_mem_id = {hdr.extended_mem_id}")
    print(f"additional_records_size = {hdr.additional_records_size}")
    print(f"suffix_map = {hdr.suffix_map}")
    print(f"sku_map = {hdr.sku_map}")
    print(f"extended_sku_map = {hdr.extended_sku_map}")
    print(f"ftm_model_name = {hdr.ftm_model_name}\n")
    return hdr


def parse_secure_partition(f, sp_offset=None, sp_size=None, sp_magic=None):
    """
    Attempt to parse the SecurePartition. If offset/size/magic are None, use defaults.
    If not found or parse fails, log a warning but don't exit script.
    """
    try:
        secp = SecurePartition(f, offset=sp_offset, size=sp_size, magic=sp_magic)
    except ValueError as e:
        print(f"No secure partition found or parse error: {e}\n")
        return

    print("Secure Partition")
    print("================")
    print(f"  offset         = {sp_offset if sp_offset else secp.DEFAULT_OFFSET}")
    print(f"  size           = {sp_size if sp_size else secp.DEFAULT_SIZE}")
    print(f"  magic          = 0x{secp.magic:X} (expected=0x{sp_magic if sp_magic else secp.DEFAULT_MAGIC:X})")
    print(f"  part_count     = {secp.part_count}")
    print(f"  signature size = {secp.sig_size}")
    print(f"  flags          = 0x{secp.flags:X}")
    print(f"  signature      = {binascii.hexlify(secp.signature)}")

    total_parts = sum(len(x) for x in secp.parts.values())
    print(f"  total named partitions = {total_parts}\n")


def parse_dz_record(f, dz_record, lenient_chunks=False):
    """
    Given the KDZ record for .dz (with offset/size), parse the .dz with the 
    option to be lenient about chunk mismatches.
    """
    f.seek(dz_record.offset)
    dz_hdr = DzHeader(f, lenient_chunks=lenient_chunks)
    print("DZ Header")
    print("=========")
    print(f"magic = 0x{dz_hdr.magic:X}")
    print(f"version = {dz_hdr.major}.{dz_hdr.minor}")
    print(f"build date = {dz_hdr.build_date}")
    print(f"compression = {dz_hdr.compression}")
    print(f"secure_image_type = {dz_hdr.secure_image_type}")
    print(f"swfv = {dz_hdr.swfv}")
    print(f"build_type = {dz_hdr.build_type}")
    print(f"android_ver = {dz_hdr.android_ver}")
    print(f"memory_size = {dz_hdr.memory_size}")
    print(f"signed_security = {dz_hdr.signed_security}")
    print(f"anti_rollback_ver = 0x{dz_hdr.anti_rollback_ver:X}")
    print(f"supported_mem = {dz_hdr.supported_mem}")
    print(f"target_product = {dz_hdr.target_product}")
    print(f"operator_code = {dz_hdr.operator_code}")
    print(f"multi_panel_mask = {dz_hdr.multi_panel_mask}")
    print(f"product_fuse_id = {dz_hdr.product_fuse_id}")
    print(f"is_factory_image = {dz_hdr.is_factory_image}")
    print(f"is_ufs = {dz_hdr.is_ufs}")
    print(f"chunk_hdrs_hash = {binascii.hexlify(dz_hdr.chunk_hdrs_hash)}")
    print(f"data_hash = {binascii.hexlify(dz_hdr.data_hash)}")
    print(f"header_crc = 0x{dz_hdr.header_crc:X}")

    total_parts = sum(len(pp) for p in dz_hdr.parts.values() for pp in p.values())
    print(f"parts total: {total_parts}\n")

    return dz_hdr


def extract_dz_parts(f, dz_hdr, out_path):
    """
    Extract partition chunks described by dz_hdr into out_path.
    Fill gaps with zero, keep track of offsets.
    """
    if dz_hdr.compression=="zlib":
        def decompressor():
            return zlib.decompressobj()
    elif dz_hdr.compression=="zstd":
        def decompressor():
            z = zstandard.ZstdDecompressor()
            return z.decompressobj()

    WRITE_FILL = b"\x00" * (4096*100)

    for hw_part, parts in dz_hdr.parts.items():
        print(f"Partition {hw_part}:")
        for pname, chunks in parts.items():
            out_file_name = os.path.join(out_path, f"{hw_part}.{pname}.img")
            print(f"  extracting part {pname} -> {out_file_name}")
            with open(out_file_name, "wb") as out_f:
                current_offset = chunks[0].part_start_sector * 4096

                for i, c in enumerate(chunks):
                    chunk_size = max(c.data_size, c.sector_count*4096)
                    print(f"    chunk {i}: {c.name} ({chunk_size} bytes)")

                    expected_offset = c.start_sector * 4096
                    while current_offset<expected_offset:
                        gap = min(expected_offset-current_offset, len(WRITE_FILL))
                        out_f.write(WRITE_FILL[:gap])
                        current_offset += gap

                    # read & decompress
                    f.seek(c.file_offset)
                    dcomp = decompressor()
                    bytes_left = c.file_size

                    while bytes_left>0:
                        rd = min(bytes_left, 1024*1024)
                        buf = f.read(rd)
                        assert len(buf)==rd, "Unexpected EOF while reading chunk data"
                        bytes_left -= rd
                        out_data = dcomp.decompress(buf)
                        out_f.write(out_data)
                        current_offset += len(out_data)

                    remainder = dcomp.flush()
                    out_f.write(remainder)
                    current_offset += len(remainder)

                last_chunk = chunks[-1]
                end_offset = (last_chunk.start_sector+last_chunk.sector_count)*4096
                while current_offset<end_offset:
                    gap = min(end_offset-current_offset, len(WRITE_FILL))
                    out_f.write(WRITE_FILL[:gap])
                    current_offset += gap
            print("")


def list_dz_partitions(dz_hdr):
    """
    List the partitions from the .dz, showing start offset, total size, and type.
    """
    print("Partition Listing (DZ)")
    print("======================")

    for hw_part, parts in dz_hdr.parts.items():
        for pname, chunks in parts.items():
            min_sect = min(c.start_sector for c in chunks)
            max_sect = max(c.start_sector + c.sector_count for c in chunks)
            start_off_bytes = min_sect*4096
            total_sz_bytes  = (max_sect - min_sect)*4096

            if any(c.is_ubi_image for c in chunks):
                ptype="ubi"
            elif any(c.is_sparse for c in chunks):
                ptype="sparse"
            else:
                ptype="raw"

            full_name = f"{hw_part}.{pname}"
            print(f"Name: {full_name}")
            print(f"  Start Offset: {start_off_bytes} (0x{start_off_bytes:X})")
            print(f"  Size:         {total_sz_bytes} (0x{total_sz_bytes:X})")
            print(f"  Type:         {ptype}\n")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("file", type=argparse.FileType("rb"),
                        help="KDZ file to parse.")
    parser.add_argument("-V", "--version", type=int, choices=[1,2,3],
                        help="Force parse KDZ as version 1,2, or 3.")
    parser.add_argument("--offset-shift", type=int, default=0,
                        help="Bytes to skip from the file start before parsing KDZ header.")
    parser.add_argument("-l", "--list", action="store_true",
                        help="List partitions from the .dz record and exit.")
    parser.add_argument("-e", "--extract-to",
                        help="Directory to which the .dz partitions are extracted.")

    # SecurePartition overrides
    parser.add_argument("--sp-offset", type=int,
                        help="Secure partition offset (default=1320).")
    parser.add_argument("--sp-size", type=int,
                        help="Secure partition size (default=82448).")
    parser.add_argument("--sp-magic", type=lambda x: int(x,0),
                        help="Secure partition magic (default=0x53430799). "
                             "Hex or decimal accepted.")

    # New fix for chunk mismatch
    parser.add_argument("--lenient-chunks", action="store_true",
                        help="Skip the 'Mismatch part start sector' assertion for .dz v1 chunks. "
                             "Log a warning and force the script's computed part_start_sector.")

    args = parser.parse_args()

    if args.offset_shift:
        args.file.seek(args.offset_shift, os.SEEK_CUR)

    # 1) Parse KDZ
    kdz_header = parse_kdz_header(args.file, forced_version=args.version)

    # 2) parse secure partition
    parse_secure_partition(
        args.file,
        sp_offset=args.sp_offset,
        sp_size=args.sp_size,
        sp_magic=args.sp_magic
    )

    # 3) find .dz record
    try:
        dz_rec = next(r for r in kdz_header.records if r.name.endswith(".dz"))
    except StopIteration:
        raise SystemExit("No .dz record found in KDZ file.")

    # 4) parse .dz with or without lenient chunk fix
    dz_hdr = parse_dz_record(args.file, dz_rec, lenient_chunks=args.lenient_chunks)

    # 5) if listing, show info then exit
    if args.list:
        list_dz_partitions(dz_hdr)
        return

    # 6) if extraction
    if args.extract_to:
        try:
            os.makedirs(args.extract_to, exist_ok=True)
        except (OSError, IOError) as e:
            if e.errno != errno.EEXIST:
                raise

        extract_dz_parts(args.file, dz_hdr, args.extract_to)
    else:
        # otherwise list chunk info
        for hw_part, parts in dz_hdr.parts.items():
            print(f"Partition {hw_part}:")
            for pname, chunks in parts.items():
                print(f"  {pname}")
                for i, c in enumerate(chunks):
                    chunk_size = max(c.data_size, c.sector_count*4096)
                    print(f"    {i}. {c.name} "
                          f"({chunk_size} bytes, sparse={c.is_sparse}, ubi={c.is_ubi_image})")
                print("")


if __name__=="__main__":
    main()
