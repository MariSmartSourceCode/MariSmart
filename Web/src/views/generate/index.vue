<template>
    <div class="dashboard-container">
        <div class="back">
            <div class="content">
                <div class="reminder">航运活动及流程</div>
                <div
                    class="pick"
                    v-for="(fitem, findex) in activity"
                    :label="fitem"
                    :key="findex"
                >
                    <el-checkbox
                        class="activityname"
                        v-model="ifActivity[fitem.num]"
                        @change="setactivity($event, fitem)"
                        >{{ fitem.desc }}</el-checkbox
                    >
                    <div class="reminder3">由以下参与方触发：</div>
                    <el-checkbox-group
                        v-model="fitem.actor"
                        @change="setactor($event, findex)"
                        size="small"
                    >
                        <el-checkbox-button
                            v-model="fitem.actor"
                            @change="setactorAll($event, findex)"
                            class="checkOperator"
                            >全选</el-checkbox-button
                        >
                        <el-checkbox-button
                            class="checkOperator"
                            v-for="(item, index) in actor"
                            :label="item"
                            :key="index"
                            >{{ item.desc }}</el-checkbox-button
                        >
                    </el-checkbox-group>

                    <div class="reminder3">处于以下状态时触发：</div>

                    <el-checkbox-group
                        v-model="fitem.pre_state"
                        @change="setprestate($event, findex)"
                        size="small"
                    >
                        <el-checkbox-button
                            class="checkOperator"
                            v-for="(item, index) in pre_state"
                            :label="item"
                            :key="index"
                            >{{ item.desc }}</el-checkbox-button
                        >
                    </el-checkbox-group>

                    <div class="reminder3">活动函数：</div>

                    <prism-editor
                        class="function-editor"
                        v-model.trim="fitem.text"
                        :line-numbers="true"
                        :tabSize="4"
                        :highlight="highlighter"
                    >
                    </prism-editor>
                </div>
                <div class="reminder2">MariSmart 合约</div>

                <el-button
                    type="primary"
                    class="checkbutton1"
                    @click="update"
                    v-loading.fullscreen.lock="loading"
                >
                    生成合约 <i class="el-icon-refresh-right"></i>
                </el-button>
                <el-button
                    type="primary"
                    class="checkbutton2"
                    @click="goVerify"
                    v-loading.fullscreen.lock="loading"
                >
                    前往验证 <i class="el-icon-right"></i>
                </el-button>
                <prism-editor
                    class="my-editor"
                    v-model.trim="code"
                    :line-numbers="true"
                    :tabSize="4"
                    :highlight="highlighter"
                >
                </prism-editor>
            </div>
        </div>
    </div>
</template>
<script>
import { PrismEditor } from "vue-prism-editor";
import "vue-prism-editor/dist/prismeditor.min.css";

import { highlight, languages } from "prismjs";
import "prismjs/components/prism-clike.min";
import "prismjs/components/prism-solidity.min";
import "prismjs/themes/prism-dark.css";

// import IoT from '@/assets/cases/IoT.txt';

export default {
    name: "generate",
    components: {
        PrismEditor,
    },
    data() {
        return {
            actor: [
                {
                    desc: "托运人",
                    num: 1,
                    name: "shipper",
                },
                {
                    desc: "承运人",
                    num: 2,
                    name: "carrier",
                },
                {
                    desc: "收货人",
                    num: 3,
                    name: "consignee",
                },
                {
                    desc: "运输前检查员",
                    num: 4,
                    name: "pre_shipment_inspector",
                },
                {
                    desc: "出口港口操作员",
                    num: 5,
                    name: "export_port_operator",
                },
                {
                    desc: "进口港口操作员",
                    num: 6,
                    name: "import_port_operator",
                },
            ],
            ifActivity: [],
            activity: [
                {
                    desc: "创建定单",
                    num: 1,
                    actor: [],
                    pre_state: [],
                    text: "",
                    name: "create",
                },
                {
                    desc: "签署定单",
                    num: 2,
                    actor: [],
                    pre_state: [],
                    text: "",
                    name: "sign",
                },
                {
                    desc: "运输前检查",
                    num: 3,
                    actor: [],
                    pre_state: [],
                    text: "",
                    name: "inspect",
                },
                {
                    desc: "出口",
                    num: 4,
                    actor: [],
                    pre_state: [],
                    text: "",
                    name: "exportShipment",
                },
                {
                    desc: "取消定单",
                    num: 5,
                    actor: [],
                    pre_state: [],
                    text: "",
                    name: "cancel",
                },
                {
                    desc: "出发",
                    num: 6,
                    actor: [],
                    pre_state: [],
                    text: "",
                    name: "depart",
                },
                {
                    desc: "报告灭失",
                    num: 7,
                    actor: [],
                    pre_state: [],
                    text: "",
                    name: "reportLoss",
                },
                {
                    desc: "报告损坏",
                    num: 8,
                    actor: [],
                    pre_state: [],
                    text: "",
                    name: "reportDamage",
                },
                {
                    desc: "到达",
                    num: 9,
                    actor: [],
                    pre_state: [],
                    text: "",
                    name: "arrive",
                },
                {
                    desc: "进口",
                    num: 10,
                    actor: [],
                    pre_state: [],
                    text: "",
                    name: "importShipment",
                },
                {
                    desc: "滞留处置",
                    num: 11,
                    actor: [],
                    pre_state: [],
                    text: "",
                    name: "rearrange",
                },
                {
                    desc: "收货",
                    num: 12,
                    actor: [],
                    pre_state: [],
                    text: "",
                    name: "receiveShipment",
                },
                {
                    desc: "申请赔偿",
                    num: 13,
                    actor: [],
                    pre_state: [],
                    text: "",
                    name: "claim",
                },
                {
                    desc: "支付赔偿",
                    num: 14,
                    actor: [],
                    pre_state: [],
                    text: "",
                    name: "compensate",
                },
                {
                    desc: "结束定单",
                    num: 15,
                    actor: [],
                    pre_state: [],
                    text: "",
                    name: "close",
                },
            ],
            pre_state: [
                {
                    desc: "已创建",
                    num: 1,
                    name: "created",
                },
                {
                    desc: "已签署",
                    num: 2,
                    name: "signed",
                },
                {
                    desc: "已检查",
                    num: 3,
                    name: "inspected",
                },
                {
                    desc: "已出口",
                    num: 4,
                    name: "exported",
                },
                {
                    desc: "已出发",
                    num: 5,
                    name: "departed",
                },
                {
                    desc: "已灭失",
                    num: 6,
                    name: "lost",
                },
                {
                    desc: "已到达",
                    num: 7,
                    name: "arrived",
                },
                {
                    desc: "已进口",
                    num: 8,
                    name: "imported",
                },
                {
                    desc: "已滞留处置",
                    num: 9,
                    name: "rearranged",
                },
                {
                    desc: "已收货",
                    num: 10,
                    name: "received",
                },
                {
                    desc: "已索赔",
                    num: 11,
                    name: "claimed",
                },
                {
                    desc: "已结束",
                    num: 12,
                    name: "closed",
                },
            ],
            code: "",
            activityList: [],
            loading: false,
            fileIndex: 0,
            readonly: false,
        };
    },
    methods: {
        highlighter(code) {
            return highlight(code, languages.sol, "sol");
        },
        readFile(name) {
            let xhr = new XMLHttpRequest();
            xhr.open("GET", "/static/" + name + ".txt", false);
            xhr.overrideMimeType("text/html;charset=utf-8");
            xhr.send(null);
            return xhr.responseText;
        },
        setactorAll(val, index) {
            this.activity[index].actor = val ? this.actor : [];
            this.isIndeterminate1 = false;
        },
        setactivity(val, item) {
            let checkedCount = val.length;
            item.text = this.readFile(item.name);
        },
        setactor(val, index) {
            let checkedCount = val.length;
        },
        setprestate(val, index) {
            let checkedCount = val.length;
        },
        goVerify() {
            this.$router.push({
                name: "dashboard",
                params: { code: this.code },
            });
        },
        update() {
            // check if activity is empty
            let flag = false;
            for (let i = 0; i < this.ifActivity.length; i++) {
                if (this.ifActivity[i]) {
                    flag = true;
                }
            }
            if (!flag) {
                this.$message.error("请至少选择一个活动");
                return;
            }
            for (let i = 0; i < this.activity.length; i++) {
                if (
                    this.activity[i].actor.length == 0 &&
                    this.ifActivity[this.activity[i].num]
                ) {
                    this.$message.error(
                        `请为${this.activity[i].desc}活动至少选择一个参与方`
                    );
                    return;
                }
                if (
                    this.activity[i].pre_state.length == 0 &&
                    this.ifActivity[this.activity[i].num]
                ) {
                    this.$message.error(
                        `请为${this.activity[i].desc}活动选择至少一个前置状态`
                    );
                    return;
                }
            }

            this.loading = true;
            // generate code
            let origin = this.readFile("module");
            let activityList = ["", "", "", "", "", ""];
            let modifier = "";
            for (let i = 0; i < this.activity.length; i++) {
                if (!this.ifActivity[this.activity[i].num]) {
                    continue;
                }
                let actor_stmt = "";
                for (let j = 0; j < this.activity[i].actor.length; j++) {
                    if (this.activity[i].actor[j]) {
                        actor_stmt += ` msg.sender == ${this.activity[i].actor[j].name} ||`;
                    }
                }
                actor_stmt = actor_stmt.substring(0, actor_stmt.length - 2);
                actor_stmt = `\t\trequire(${actor_stmt});\n`;

                let pre_state_stmt = "";
                for (let j = 0; j < this.activity[i].pre_state.length; j++) {
                    if (this.activity[i].pre_state[j]) {
                        pre_state_stmt += ` state == ${this.activity[i].pre_state[j].name} ||`;
                    }
                }
                pre_state_stmt = pre_state_stmt.substring(
                    0,
                    pre_state_stmt.length - 2
                );
                pre_state_stmt = `\t\trequire(${pre_state_stmt});\n`;

                modifier += `\tmodifier pre_${this.activity[i].name} override () {\n${actor_stmt}${pre_state_stmt}\t\t_;\n\t}\n\n`;

                for (let j = 0; j < this.activity[i].actor.length; j++) {
                    if (this.activity[i].actor[j]) {
                        activityList[this.activity[i].actor[j].num - 1] +=
                            this.activity[i].text + `\n`;
                    }
                }
            }
            origin = origin.replace("MODIFIER", modifier);
            for (let i = 0; i < activityList.length; i++) {
                origin = origin.replace(
                    `${this.actor[i].name}_function`,
                    activityList[i]
                );
            }
            this.loading = false;
            this.code = origin;
            return;
        },
    },
};
</script>
<style scoped lang="scss">
/* required class */
.my-editor {
    background: #2d2d2d;
    color: #ccc;
    font-family: Fira code, Fira Mono, Consolas, Menlo, Courier, monospace;
    font-size: 14px;
    line-height: 1.5;
    padding-top: 15px;

    height: 1300px;
    border-radius: 5px;
    top: 70px;
    left: 630px;
    right: 15px;
    width: auto;
    position: absolute;
}
.function-editor {
    background: #2d2d2d;
    color: #ccc;
    font-family: Fira code, Fira Mono, Consolas, Menlo, Courier, monospace;
    font-size: 14px;
    border-radius: 5px;
    position: relative;
    padding: 10px;
    margin: 10px;
    height: auto;
}
.prism-editor__textarea:focus {
    outline: none;
}
.content {
    left: 10px;
    right: 10px;
    top: 70px;
    height: 1390px;
    position: absolute;
    border-radius: 10px;
    background-color: #f9fafb;
    box-shadow: 0px 0px 10px 10px #eff1f3;
}
.back {
    background-color: #f9fafb;
    height: 1460px;
}
.pick {
    height: auto;
    border-radius: 5px;
    background-color: white;
    position: relative;
    left: 15px;
    top: 70px;
    width: 600px;
    padding: 10px;
    padding-top: 20px;
    box-shadow: 0px 0px 2px 2px #eff1f3;
}
.el-checkbox__label {
    display: inline-grid;
    white-space: pre-line;
    margin-right: 30px;
    word-wrap: break-word;
    width: 400px;
}
.el-checkbox {
    color: #333333 !important;
}
.checkbox {
    font-size: 20px;
    left: 10px;
}
.reminder {
    font-size: 20px;
    position: absolute;
    top: 25px;
    left: 20px;
    color: #575c66 !important;
    font-weight: 500;
}

.reminder2 {
    font-size: 20px;
    position: absolute;
    top: 25px;
    left: 635px;
    color: #575c66;
    font-weight: 500;
}
.reminder3 {
    font-size: 14px;
    position: relative;
    top: 10px;
    left: 20px;
    color: #818998;
    line-height: 30px;
}
.classes {
    font-size: 14px;
    font-weight: bold;
    color: #818998;
    left: 25px;
    height: 50px;
    position: relative;
    line-height: 0px;
}
.activityname {
    font-size: 14px;
    font-weight: bold;
    color: #818998;
    left: 0px;
    height: 15px;
    position: relative;
    line-height: 0px;
}
.checkbutton1 {
    font-size: 20px;
    right: 225px;
    position: absolute;
    font-weight: bold;
    top: 15px;
}
.checkbutton2 {
    font-size: 20px;
    right: 25px;
    position: absolute;
    font-weight: bold;
    top: 15px;
}
.addpropbutton {
    font-size: 14px;
    font-weight: bold;
    max-width: 63px;
    max-height: 23px;
    display: flex;
    justify-content: center;
    align-items: center;
    position: relative;
    top: -10px;
}
.diytable {
    top: -10px;
    position: relative;
}
.checkOperator {
    position: relative;
    top: 10px;
    left: 20px;
    size: 14px;
}
.filepicker {
    position: absolute;
    top: 20px;
    left: 880px;
}
.filepickerbutton {
    font-size: 18px;
    font-weight: bold;
}
.proptip {
    top: 5px;
    position: relative;
    border: 0;
    font-size: 17px;
    width: 17px;
    height: 17px;
    display: flex;
    justify-content: center;
    align-items: center;
    background-color: white;
}
</style>
