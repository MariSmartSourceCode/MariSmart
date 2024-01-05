<template>
    <div class="dashboard-container">
        <div class="back">
            <div class="content">
                <div class="title">Verfication Result</div>
                <el-divider v-if="ifClass1"></el-divider>
                <div v-if="ifClass1" class="classTitle">
                    Workflow correctness
                </div>
                <div
                    v-for="(item, index) in checkList1"
                    :key="index"
                    class="resultbox"
                >
                    <el-row>
                        <el-col :span="1" class="flag">
                            <i
                                v-if="result[index].result == 'true'"
                                class="el-icon-success"
                                style="color: rgb(0, 175, 0); font-size: 20px;"
                            ></i>
                            <i
                                v-else
                                class="el-icon-error"
                                style="color: red; font-size: 20px;"
                            ></i>
                            <!-- <i v-if="result[index].result == 'false'" class="el-icon-error" style="color: red; font-size: 20px;"></i> -->
                            <!-- <i v-if="" class="el-icon-remove" style="color: grey; font-size: 20px;"></i> -->
                            <!-- <div class="desc">{{ index+1 }}.</div> -->
                        </el-col>
                        <el-col :span="20">
                            <div class="desc" style="font-weight: 600;">
                                {{ item.desc }}
                            </div>
                            <div class="desc">property: {{ item.prop }}</div>
                            <div class="desc">
                                time: {{ result[index].time }} ms
                            </div>
                            <div
                                v-if="result[index].result == 'false'"
                                class="desc"
                                style="5px;"
                            >
                                <el-button
                                    plain
                                    class="example"
                                    size="mini"
                                    @click="showExample(result[index])"
                                    >see counterexample</el-button
                                >
                            </div>
                        </el-col>
                    </el-row>
                </div>
                <el-divider v-if="ifClass2"></el-divider>
                <div v-if="ifClass2" class="classTitle">
                    Payment correctness
                </div>
                <div
                    v-for="(item, index) in checkList2"
                    :key="index"
                    class="resultbox"
                >
                    <el-row>
                        <el-col :span="1" class="flag">
                            <i
                                v-if="result[index + 6].result == 'true'"
                                class="el-icon-success"
                                style="color: rgb(0, 175, 0); font-size: 20px;"
                            ></i>
                            <i
                                v-else
                                class="el-icon-error"
                                style="color: red; font-size: 20px;"
                            ></i>
                            <!-- <i v-if="" class="el-icon-remove" style="color: grey; font-size: 20px;"></i> -->
                            <!-- <div class="desc">{{ index+1 }}.</div> -->
                        </el-col>
                        <el-col :span="23">
                            <div class="desc" style="font-weight: 600;">
                                {{ item.desc }}
                            </div>
                            <div class="desc">property: {{ item.prop }}</div>
                            <div class="desc">
                                time: {{ result[index + 6].time }} ms
                            </div>
                            <div
                                v-if="result[index + 6].result == 'false'"
                                class="desc"
                                style="5px;"
                            >
                                <el-button
                                    plain
                                    class="example"
                                    size="mini"
                                    @click="showExample(result[index + 6])"
                                    >see counterexample</el-button
                                >
                            </div>
                        </el-col>
                    </el-row>
                </div>
                <el-divider v-if="ifClass3"></el-divider>
                <div v-if="ifClass3" class="classTitle">
                    Accident compensation
                </div>
                <div
                    v-for="(item, index) in checkList3"
                    :key="index"
                    class="resultbox"
                >
                    <el-row>
                        <el-col :span="1" class="flag">
                            <i
                                v-if="result[index + 10].result == 'true'"
                                class="el-icon-success"
                                style="color: rgb(0, 175, 0); font-size: 20px;"
                            ></i>
                            <i
                                v-else
                                class="el-icon-error"
                                style="color: red; font-size: 20px;"
                            ></i>
                            <!-- <i v-if="" class="el-icon-remove" style="color: grey; font-size: 20px;"></i> -->
                            <!-- <div class="desc">{{ index+1 }}.</div> -->
                        </el-col>
                        <el-col :span="23">
                            <div class="desc" style="font-weight: 600;">
                                {{ item.desc }}
                            </div>
                            <div class="desc">property: {{ item.prop }}</div>
                            <div class="desc">
                                time: {{ result[index + 10].time }} ms
                            </div>
                            <div
                                v-if="result[index + 10].result == 'false'"
                                class="desc"
                                style="5px;"
                            >
                                <el-button
                                    plain
                                    class="example"
                                    size="mini"
                                    @click="showExample(result[index + 10])"
                                    >see counterexample</el-button
                                >
                            </div>
                        </el-col>
                    </el-row>
                </div>
                <el-divider v-if="ifClass4"></el-divider>
                <div v-if="ifClass4" class="classTitle">
                    Legality (Hamburg Rules)
                </div>
                <div
                    v-for="(item, index) in checkList4"
                    :key="index"
                    class="resultbox"
                >
                    <el-row>
                        <el-col :span="1" class="flag">
                            <i
                                v-if="result[index + 16].result == 'true'"
                                class="el-icon-success"
                                style="color: rgb(0, 175, 0); font-size: 20px;"
                            ></i>
                            <i
                                v-else
                                class="el-icon-error"
                                style="color: red; font-size: 20px;"
                            ></i>
                            <!-- <i v-if="" class="el-icon-remove" style="color: grey; font-size: 20px;"></i> -->
                            <!-- <div class="desc">{{ index+1 }}.</div> -->
                        </el-col>
                        <el-col :span="23">
                            <div class="desc" style="font-weight: 600;">
                                {{ item.desc }}
                            </div>
                            <div class="desc">property: {{ item.prop }}</div>
                            <div class="desc">
                                time: {{ result[index + 16].time }} ms
                            </div>
                            <div
                                v-if="result[index + 16].result == 'false'"
                                class="desc"
                                style="5px;"
                            >
                                <el-button
                                    plain
                                    class="example"
                                    size="mini"
                                    @click="showExample(result[index + 16])"
                                    >see counterexample</el-button
                                >
                            </div>
                        </el-col>
                    </el-row>
                </div>
                <el-divider v-if="ifClass5"></el-divider>
                <div v-if="ifClass5" class="classTitle">
                    Legality (Maritime Laws of PRC.)
                </div>
                <div
                    v-for="(item, index) in checkList5"
                    :key="index"
                    class="resultbox"
                >
                    <el-row>
                        <el-col :span="1" class="flag">
                            <i
                                v-if="result[index + 21].result == 'true'"
                                class="el-icon-success"
                                style="color: rgb(0, 175, 0); font-size: 20px;"
                            ></i>
                            <i
                                v-else
                                class="el-icon-error"
                                style="color: red; font-size: 20px;"
                            ></i>
                            <!-- <i v-if="" class="el-icon-remove" style="color: grey; font-size: 20px;"></i> -->
                            <!-- <div class="desc">{{ index+1 }}.</div> -->
                        </el-col>
                        <el-col :span="23">
                            <div class="desc" style="font-weight: 600;">
                                {{ item.desc }}
                            </div>
                            <div class="desc">property: {{ item.prop }}</div>
                            <div class="desc">
                                time: {{ result[index + 21].time }} ms
                            </div>
                            <div
                                v-if="result[index + 21].result == 'false'"
                                class="desc"
                                style="5px;"
                            >
                                <el-button
                                    plain
                                    class="example"
                                    size="mini"
                                    @click="showExample(result[index + 21])"
                                    >see counterexample</el-button
                                >
                            </div>
                        </el-col>
                    </el-row>
                </div>
                <el-divider v-if="ifDiy"></el-divider>
                <div v-if="ifDiy" class="classTitle">Custom properties</div>
                <div
                    v-for="(item, index) in diyList"
                    :key="index"
                    class="resultbox"
                >
                    <el-row>
                        <el-col :span="1" class="flag">
                            <!-- <i v-if="" class="el-icon-success" style="color: rgb(0, 175, 0); font-size: 20px;"></i> -->
                            <!-- <i v-else class="el-icon-error" style="color: red; font-size: 20px;"></i> -->
                            <i
                                v-if="true"
                                class="el-icon-remove"
                                style="color: grey; font-size: 20px;"
                            ></i>
                            <!-- <div class="desc">{{ index+1 }}.</div> -->
                        </el-col>
                        <el-col :span="23">
                            <div class="desc" style="font-weight: 600;">
                                {{ item.desc }}
                            </div>
                            <div class="desc">property: {{ item.prop }}</div>
                            <!-- <div class="desc">time: {{ result[index+6].time }} ms</div>
                                <div v-if="result[index+6].result == 'false'" class="desc" style="5px;">
                                    <el-button plain class="example" size="mini" @click="showExample(result[index+6])">see counterexample</el-button>
                                </div> -->
                        </el-col>
                    </el-row>
                </div>
                <el-dialog
                    title="counterexample"
                    :visible.sync="visible"
                    width="80%"
                    top="30px"
                    center
                >
                    <div class="dialog">{{ example }}</div>
                </el-dialog>
            </div>
            <div style="position: absolute; content: ''; bottom: -10px;"></div>
        </div>
    </div>
</template>
<script>
export default {
    name: "result",
    data() {
        return {
            filename: "",
            checkList1: [],
            checkList2: [],
            checkList3: [],
            checkList4: [],
            checkList5: [],
            diyList: [],
            ifClass1: false,
            ifClass2: false,
            ifClass3: false,
            ifClass4: false,
            ifClass5: false,
            ifDiy: false,
            visible: false,
            example: "",
            result: "",
        };
    },
    methods: {
        readFile(name) {
            let xhr = new XMLHttpRequest();
            xhr.open("GET", "/static/" + name + ".txt", false);
            xhr.overrideMimeType("text/html;charset=utf-8");
            xhr.send(null);
            return xhr.responseText;
        },
        showExample(result) {
            this.visible = true;
            this.example = result.counter_example;
        },
    },
    created() {
        this.filename = this.$route.params.filename;
        this.checkList1 = Array.from(this.$route.params.checkList1);
        this.checkList2 = Array.from(this.$route.params.checkList2);
        this.checkList3 = Array.from(this.$route.params.checkList3);
        this.checkList4 = Array.from(this.$route.params.checkList4);
        this.checkList5 = Array.from(this.$route.params.checkList5);

        this.ifClass1 = true;
        this.ifClass2 = true;
        this.ifClass3 = true;
        this.ifClass4 = true;
        this.ifClass5 = true;
        this.ifDiy = false;

        this.result = JSON.parse(this.readFile(this.filename + "_res"))[
            "result"
        ];
    },
};
</script>
<style scoped lang="scss">
.content {
    top: 50px;
    height: auto;
    left: 10%;
    width: 80%;
    position: relative;
    border-radius: 10px;
    background-color: #fff;
    box-shadow: 0px 0px 10px 10px #eff1f3;
    padding: 20px;
}
.back {
    position: relative;
    background-color: #f9fafb;
    width: 100%;
    height: auto;
}
.title {
    font-size: 45px;
    color: #575c66;
    font-weight: bold;
    width: 100%;
    position: relative;
    text-align: center;
}
.classTitle {
    font-size: 20px;
    font-weight: bold;
    color: #818998;
    left: 10px;
    position: relative;
}
.desc {
    font-size: 20px;
    color: #333333;
    min-height: 30px;
    //height: auto;
    position: relative;
    // border: 1px solid;
    //margin: 0px;
    display: inline-block;
    width: 100%;
    //top: -18px;
}
.resultbox {
    left: 20px;
    margin-top: 20px;
    //margin-right: 8%;
    position: relative;
    word-wrap: break-word;
    white-space: pre-wrap;
}
.flag {
    font-size: 20px;
    min-height: 30px;
    position: relative;
    // border: 1px solid;
    margin: 0px;
    left: 15px;
}
.example {
    font-size: 18px;
    font-weight: bold;
    color: #333333;
}
.dialog {
    white-space: pre-wrap;
}
</style>
