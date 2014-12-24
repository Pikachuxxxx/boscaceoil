package co.sparemind.trackermodule {
	public class XMSong {
		import flash.utils.IDataOutput;
		import flash.utils.ByteArray;
		import flash.utils.Endian;
		import flash.geom.Rectangle;

		public var songname:ByteArray = new ByteArray();
		public var trackerName:String = 'FastTracker v2.00   ';
		public var songLength:uint = 0;
		public var restartPos:uint;
		public var numChannels:uint = 8; // bosca has a hard-coded limit
		public var numPatterns:uint = 0;
		public var numInstruments:uint;
		public var instruments:Vector.<XMInstrument> = new Vector.<XMInstrument>;
		public var defaultTempo:uint;
		public var defaultBPM:uint;
		public var patternOrderTable:Array = [
			0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
			0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
			0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
			0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
			0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
			0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
			0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
			0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
			0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
			0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
			0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
			0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
			0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
			0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
			0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
			0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
				];

		public var flags:uint;

		// physical considerations, only relevant for writing
		private var headerSize:uint = 20 + 256;
		private var idText:String = 'Extended Module: ';
		private var sep:uint = 26; // DOS EOF
		private var version:uint = 0x0104;

		public var patterns:Vector.<XMPattern> = new Vector.<XMPattern>;

		public function writeToStream(stream:IDataOutput):void {
			var xm:XMSong = this;
			var headbuf:ByteArray = new ByteArray;
			headbuf.endian = Endian.LITTLE_ENDIAN;

			headbuf.writeMultiByte(xm.idText, 'us-ascii'); // physical
			headbuf.writeBytes(xm.songname);
			headbuf.writeByte(xm.sep); // physical
			headbuf.writeMultiByte(xm.trackerName, 'us-ascii');
			headbuf.writeShort(xm.version); // physical? probably
			headbuf.writeUnsignedInt(xm.headerSize); // physical
			headbuf.writeShort(xm.songLength);
			headbuf.writeShort(xm.restartPos);
			headbuf.writeShort(xm.numChannels);
			headbuf.writeShort(xm.numPatterns);
			headbuf.writeShort(xm.numInstruments);
			headbuf.writeShort(xm.flags); // physical?
			headbuf.writeShort(xm.defaultTempo);
			headbuf.writeShort(xm.defaultBPM);
			for (var i:int = 0; i < xm.patternOrderTable.length; i++) {
				headbuf.writeByte(xm.patternOrderTable[i]);
			}


			stream.writeBytes(headbuf);
			for (i = 0; i < xm.patterns.length; i++) {
				var pattern:XMPattern = xm.patterns[i];
				var patbuf:ByteArray = new ByteArray();
				patbuf.endian = Endian.LITTLE_ENDIAN;
				var patternHeaderLength:uint = 9; // TODO: calculate
				patbuf.writeUnsignedInt(patternHeaderLength);
				patbuf.writeByte(0); // packingType
				patbuf.writeShort(pattern.rows.length);

				var patBodyBuf:ByteArray = new ByteArray();
				patBodyBuf.endian = Endian.LITTLE_ENDIAN;
				for (var rownum:uint = 0; rownum < pattern.rows.length; rownum++) {
					var line:XMPatternLine = pattern.rows[rownum];
					for (var chan:uint = 0; chan < line.cellOnTrack.length; chan++) {
						var cell:XMPatternCell = line.cellOnTrack[chan];
						if (cell.isEmpty()) {
							patBodyBuf.writeByte(0x80);
							continue;
						}
						patBodyBuf.writeByte(cell.note);
						patBodyBuf.writeByte(cell.instrument);
						patBodyBuf.writeByte(cell.volume);
						patBodyBuf.writeByte(cell.effect);
						patBodyBuf.writeByte(cell.effectParam);
					}
				}

				patbuf.writeShort(patBodyBuf.length); // packedDataSize
				stream.writeBytes(patbuf);
				stream.writeBytes(patBodyBuf);
			}

			for (var instno:uint = 0; instno < xm.instruments.length; instno++) {
				var inst:XMInstrument = xm.instruments[instno];
				var instrheadbuf:ByteArray = new ByteArray();
				instrheadbuf.endian = Endian.LITTLE_ENDIAN;
				var headerSize:uint = (inst.samples.length < 1) ? 29 : 263;
				instrheadbuf.writeUnsignedInt(headerSize);
				instrheadbuf.writeMultiByte(inst.name, 'us-ascii');
				instrheadbuf.writeByte(0); // type
				instrheadbuf.writeShort(inst.samples.length);
				if (inst.samples.length < 1) {
					stream.writeBytes(instrheadbuf);
				}
				instrheadbuf.writeUnsignedInt(40); // sampleHeaderSize
				for (var kma:uint = 0; kma < inst.keymapAssignments.length; kma++) {
					instrheadbuf.writeByte(inst.keymapAssignments[kma]);
				}
				for (var p:uint = 0; p < 12; p++) {
					// var point:XMEnvelopePoint = inst.volumeEnvelope.points[p];
					// instrheadbuf.writeShort(point.x);
					// instrheadbuf.writeShort(point.y);
					instrheadbuf.writeShort(0x1111);
					instrheadbuf.writeShort(0x2222);
				}
				for (p = 0; p < 12; p++) {
					// var point:XMEnvelopePoint = inst.panningEnvelope.points[p];
					// instrheadbuf.writeShort(point.x);
					// instrheadbuf.writeShort(point.y);
					instrheadbuf.writeShort(0xdeed);
					instrheadbuf.writeShort(0xfeef);
				}
				instrheadbuf.writeByte(0); // numVolumePoints
				instrheadbuf.writeByte(0); // numVolumePoints
				instrheadbuf.writeByte(0); // volSustainPoint
				instrheadbuf.writeByte(0); // volLoopStartPoint
				instrheadbuf.writeByte(0); // volLoopEndPoint
				instrheadbuf.writeByte(0); // panSustainPoint
				instrheadbuf.writeByte(0); // panLoopStartPoint
				instrheadbuf.writeByte(0); // panLoopEndPoint
				instrheadbuf.writeByte(0); // volumeType
				instrheadbuf.writeByte(0); // panningType
				instrheadbuf.writeByte(0); // vibratoType
				instrheadbuf.writeByte(0); // vibratoSweep
				instrheadbuf.writeByte(0); // vibratoDepth
				instrheadbuf.writeByte(0); // vibratoRate
				instrheadbuf.writeShort(0); // volumeFadeout);
				// the 22 bytes at offset +241 are reserved
				for (i = 0; i < 22; i++) {
					instrheadbuf.writeByte(0x00);
				}
				stream.writeBytes(instrheadbuf);
				for (var s:uint = 0; s < inst.samples.length; s++) {
					var sample:XMSample = inst.samples[s];
					var sampleHeadBuf:ByteArray = new ByteArray();
					sampleHeadBuf.endian = Endian.LITTLE_ENDIAN;
					sampleHeadBuf.writeUnsignedInt(sample.data.length);
					sampleHeadBuf.writeUnsignedInt(sample.loopStart);
					sampleHeadBuf.writeUnsignedInt(sample.loopLength);
					sampleHeadBuf.writeByte(sample.volume);
					sampleHeadBuf.writeByte(sample.finetune);
					var sampleType:uint = (sample.loopsForward ? 1 : 0) |
						(sample.bitsPerSample == 16 ? 2 : 0);
					sampleHeadBuf.writeByte(sampleType);
					sampleHeadBuf.writeByte(sample.panning);
					sampleHeadBuf.writeByte(sample.relativeNoteNumber);
					sampleHeadBuf.writeByte(0); // regular 'delta' sample encoding
					sampleHeadBuf.writeMultiByte(sample.name, 'us-ascii');
					stream.writeBytes(sampleHeadBuf);
				}
				for (s = 0; s < inst.samples.length; s++) {
					sample = inst.samples[s];
					stream.writeBytes(sample.data);
				}
			}
		}

		public function addInstrument(instrument:XMInstrument):void {
			instruments.push(instrument);
		}

	}
}

