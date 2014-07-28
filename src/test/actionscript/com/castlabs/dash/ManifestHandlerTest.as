package com.castlabs.dash {
import com.castlabs.dash.handlers.ManifestHandler;

import org.flexunit.assertThat;
import org.hamcrest.object.equalTo;

public class ManifestHandlerTest{
    public function ManifestHandlerTest() {
    }

    [Test]
    public function testSegmentBase():void {
        var xml:XML =
            <MPD type="static" mediaPresentationDuration="PT9M56S">
                <Period>
                    <AdaptationSet>
                        <Representation mimeType="video/mp4" id="avc1-bbb-480p-250k.mp4" bandwidth="252000">
                            <BaseURL>avc1-bbb-480p-250k.mp4</BaseURL>
                            <SegmentBase indexRange="708-2011">
                                <Initialization range="44-707"/>
                            </SegmentBase>
                        </Representation>
                    </AdaptationSet>
                    <AdaptationSet>
                        <Representation mimeType="audio/mp4" id="mp4a-bbb-69k.mp4" bandwidth="69000">
                            <BaseURL>mp4a-bbb-69k.mp4</BaseURL>
                            <SegmentBase indexRange="658-2117">
                                <Initialization range="44-657"/>
                            </SegmentBase>
                        </Representation>
                    </AdaptationSet>
                </Period>
            </MPD>;

        var handler: ManifestHandler = new ManifestHandler("http://localhost/Manifest.mpd", xml);

        assertThat(handler.duration, equalTo(596));
        assertThat(handler.live, equalTo(false));
        assertThat(handler.audioRepresentations.length, equalTo(1));
        assertThat(handler.audioRepresentations[0].id, equalTo("mp4a-bbb-69k.mp4"));
        assertThat(handler.audioRepresentations[0].bandwidth, equalTo(69000));
        assertThat(handler.videoRepresentations.length, equalTo(1));
        assertThat(handler.videoRepresentations[0].id, equalTo("avc1-bbb-480p-250k.mp4"));
        assertThat(handler.videoRepresentations[0].bandwidth, equalTo(252000));
    }

    [Test]
    public function testSegmentList():void {
        var xml:XML =
            <MPD type="static" mediaPresentationDuration="PT9M56S">
                <Period>
                    <AdaptationSet>
                        <Representation mimeType="video/mp4" id="1" bandwidth="252000">
                            <SegmentList duration="144000" timescale="24000">
                                <Initialization sourceURL="bbb.mp4_segment_0000.m4s"/>
                                <SegmentURL media="bbb.mp4_segment_1.m4s"/>
                            </SegmentList>
                        </Representation>
                    </AdaptationSet>
                    <AdaptationSet>
                        <Representation mimeType="audio/mp4" id="2" bandwidth="69000">
                            <SegmentList duration="288000" timescale="48000">
                                <Initialization sourceURL="bbb_aud.mp4_segment_0000.m4s"/>
                                <SegmentURL media="bbb_aud.mp4_segment_1.m4s"/>
                            </SegmentList>
                        </Representation>
                    </AdaptationSet>
                </Period>
            </MPD>;

        var handler: ManifestHandler = new ManifestHandler("http://localhost/Manifest.mpd", xml);

        assertThat(handler.live, equalTo(false));
        assertThat(handler.duration, equalTo(596));
        assertThat(handler.videoRepresentations.length, equalTo(1));
        assertThat(handler.videoRepresentations[0].id, equalTo("1"));
        assertThat(handler.videoRepresentations[0].bandwidth, equalTo(252000));
        assertThat(handler.audioRepresentations.length, equalTo(1));
        assertThat(handler.audioRepresentations[0].id, equalTo("2"));
        assertThat(handler.audioRepresentations[0].bandwidth, equalTo(69000));
    }

    [Test]
    public function testSegmentTemplate():void {
        var xml:XML =
            <MPD type="static" mediaPresentationDuration="PT9M56S">
                <Period>
                    <AdaptationSet>
                        <Representation mimeType="video/mp4" id="1" bandwidth="252000">
                            <SegmentTemplate timescale="12288" duration="36864" media="avc1-bbb-436p-250k_$Number$.m4s"
                                startNumber="1" initialization="avc1-bbb-436p-250k_init.mp4"/>
                        </Representation>
                    </AdaptationSet>
                    <AdaptationSet>
                        <Representation mimeType="audio/mp4" id="2" bandwidth="69000">
                            <SegmentTemplate timescale="48000" duration="143328" media="mp4a-bbb-69k_$Number$.m4s"
                                startNumber="1" initialization="mp4a-bbb-69k_init.mp4"/>
                        </Representation>
                    </AdaptationSet>
                </Period>
            </MPD>;

        var handler: ManifestHandler = new ManifestHandler("http://localhost/Manifest.mpd", xml);

        assertThat(handler.live, equalTo(false));
        assertThat(handler.duration, equalTo(596));
        assertThat(handler.videoRepresentations.length, equalTo(1));
        assertThat(handler.videoRepresentations[0].id, equalTo("1"));
        assertThat(handler.videoRepresentations[0].bandwidth, equalTo(252000));
        assertThat(handler.audioRepresentations.length, equalTo(1));
        assertThat(handler.audioRepresentations[0].id, equalTo("2"));
        assertThat(handler.audioRepresentations[0].bandwidth, equalTo(69000));
    }

    [Test]
    public function testSegmentLive():void {
        var xml:XML =
            <MPD type="dynamic" mediaPresentationDuration="PT9M56S" minimumUpdatePeriod="PT2S"
                    timeShiftBufferDepth="PT10M" minBufferTime="PT10S">
                <Period>
                    <AdaptationSet>
                        <Representation mimeType="video/mp4" id="1" bandwidth="252000">
                            <SegmentTemplate timescale="44100" initialization="channel1-$RepresentationID$.dash"
                                    media="channel1-$RepresentationID$-$Time$.dash">
                                <SegmentTimeline>
                                    <S t="0" d="173057" />
                                    <S d="88064" />
                                </SegmentTimeline>
                            </SegmentTemplate>
                        </Representation>
                    </AdaptationSet>
                    <AdaptationSet>
                        <Representation mimeType="audio/mp4" id="2" bandwidth="69000">
                            <SegmentTemplate timescale="1000" initialization="channel1-$RepresentationID$.dash"
                                    media="channel1-$RepresentationID$-$Time$.dash">
                                <SegmentTimeline>
                                    <S t="0" d="2000" r="89" />
                                </SegmentTimeline>
                            </SegmentTemplate>
                        </Representation>
                    </AdaptationSet>
                </Period>
            </MPD>;

        var handler: ManifestHandler = new ManifestHandler("http://localhost/Manifest.mpd", xml, true);

        assertThat(handler.live, equalTo(true));
        assertThat(handler.duration, equalTo(596));
        assertThat(handler.videoRepresentations.length, equalTo(1));
        assertThat(handler.videoRepresentations[0].id, equalTo("1"));
        assertThat(handler.videoRepresentations[0].bandwidth, equalTo(252000));
        assertThat(handler.audioRepresentations.length, equalTo(1));
        assertThat(handler.audioRepresentations[0].id, equalTo("2"));
        assertThat(handler.audioRepresentations[0].bandwidth, equalTo(69000));
    }
}
}
