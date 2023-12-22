<template>
    <div class="dashboard-container">
        <div class="back">
            <div class="content">
                <div class="reminder">请选择或自定义待检测性质</div>
                <div class="pick">
                    <div class="classes">工作流正确性性质</div>
                    <el-checkbox
                        :indeterminate="isIndeterminate1"
                        v-model="ifCheckAll1"
                        @change="checkAll1"
                        class="checkAll"
                        >全选</el-checkbox
                    >
                    <el-checkbox-group v-model="checkList1" @change="checked1">
                        <el-row v-for="(item, index) in prop1" :key="index">
                            <el-col :span="22">
                                <el-checkbox :label="item" class="checkbox">{{
                                    item.desc
                                }}</el-checkbox>
                            </el-col>
                            <el-col :span="2">
                                <el-tooltip
                                    effect="light"
                                    :content="item.prop"
                                    placement="right"
                                >
                                    <el-tag class="proptip" type="info">
                                        <i class="el-icon-question"></i>
                                    </el-tag>
                                </el-tooltip>
                            </el-col>
                        </el-row>
                    </el-checkbox-group>
                    <el-divider></el-divider>
                    <div class="classes">支付正确性性质</div>
                    <el-checkbox
                        :indeterminate="isIndeterminate2"
                        v-model="ifCheckAll2"
                        @change="checkAll2"
                        class="checkAll"
                        >全选</el-checkbox
                    >
                    <el-checkbox-group v-model="checkList2" @change="checked2">
                        <el-row v-for="(item, index) in prop2" :key="index">
                            <el-col :span="22">
                                <el-checkbox :label="item" class="checkbox">{{
                                    item.desc
                                }}</el-checkbox>
                            </el-col>
                            <el-col :span="2">
                                <el-tooltip
                                    effect="light"
                                    :content="item.prop"
                                    placement="right"
                                >
                                    <el-tag class="proptip" type="info">
                                        <i class="el-icon-question"></i>
                                    </el-tag>
                                </el-tooltip>
                            </el-col>
                        </el-row>
                    </el-checkbox-group>
                    <el-divider></el-divider>
                    <div class="classes">异常处理正确性性质</div>
                    <el-checkbox
                        :indeterminate="isIndeterminate3"
                        v-model="ifCheckAll3"
                        @change="checkAll3"
                        class="checkAll"
                        >全选</el-checkbox
                    >
                    <el-checkbox-group v-model="checkList3" @change="checked3">
                        <el-row v-for="(item, index) in prop3" :key="index">
                            <el-col :span="22">
                                <el-checkbox :label="item" class="checkbox">{{
                                    item.desc
                                }}</el-checkbox>
                            </el-col>
                            <el-col :span="2">
                                <el-tooltip
                                    effect="light"
                                    :content="item.prop"
                                    placement="right"
                                >
                                    <el-tag class="proptip" type="info">
                                        <i class="el-icon-question"></i>
                                    </el-tag>
                                </el-tooltip>
                            </el-col>
                        </el-row>
                    </el-checkbox-group>
                    <el-divider></el-divider>
                    <div class="classes">合规性性质（汉堡规则）</div>
                    <el-checkbox
                        :indeterminate="isIndeterminate4"
                        v-model="ifCheckAll4"
                        @change="checkAll4"
                        class="checkAll"
                        >全选</el-checkbox
                    >
                    <el-checkbox-group v-model="checkList4" @change="checked4">
                        <el-row v-for="(item, index) in prop4" :key="index">
                            <el-col :span="22">
                                <el-checkbox :label="item" class="checkbox">{{
                                    item.desc
                                }}</el-checkbox>
                            </el-col>
                            <el-col :span="2">
                                <el-tooltip
                                    effect="light"
                                    :content="item.prop"
                                    placement="right"
                                >
                                    <el-tag class="proptip" type="info">
                                        <i class="el-icon-question"></i>
                                    </el-tag>
                                </el-tooltip>
                            </el-col>
                        </el-row>
                    </el-checkbox-group>
                    <el-divider></el-divider>
                    <div class="classes">合规性性质（中国海商法）</div>
                    <el-checkbox
                        :indeterminate="isIndeterminate5"
                        v-model="ifCheckAll5"
                        @change="checkAll5"
                        class="checkAll"
                        >全选</el-checkbox
                    >
                    <el-checkbox-group v-model="checkList5" @change="checked5">
                        <el-row v-for="(item, index) in prop5" :key="index">
                            <el-col :span="22">
                                <el-checkbox :label="item" class="checkbox">{{
                                    item.desc
                                }}</el-checkbox>
                            </el-col>
                            <el-col :span="2">
                                <el-tooltip
                                    effect="light"
                                    :content="item.prop"
                                    placement="right"
                                >
                                    <el-tag class="proptip" type="info">
                                        <i class="el-icon-question"></i>
                                    </el-tag>
                                </el-tooltip>
                            </el-col>
                        </el-row>
                    </el-checkbox-group>
                    <el-divider></el-divider>
                    <el-col :span="20">
                        <div class="classes">
                            自定义性质
                        </div>
                    </el-col>
                    <el-col :span="4">
                        <el-button
                            type="primary"
                            size="mini"
                            class="addpropbutton"
                            @click="addProp"
                            >添加性质</el-button
                        >
                    </el-col>
                    <el-table
                        :data="diyList"
                        class="diytable"
                        height="220"
                        style="width: 100%"
                    >
                        <el-table-column label="规范" prop="prop" width="300">
                            <template slot-scope="scope">
                                <el-input
                                    v-model.trim="scope.row.prop"
                                    placeholder="必填"
                                ></el-input>
                            </template>
                        </el-table-column>
                        <el-table-column label="描述" prop="desc" width="200">
                            <template slot-scope="scope">
                                <el-input
                                    v-model.trim="scope.row.desc"
                                    placeholder="选填"
                                ></el-input>
                            </template>
                        </el-table-column>
                        <el-table-column label="操作" width="80" align="center">
                            <template slot-scope="scope">
                                <el-button
                                    type="text"
                                    icon="el-icon-delete"
                                    @click="deleteProp(scope.$index, scope.row)"
                                ></el-button>
                            </template>
                        </el-table-column>
                    </el-table>
                </div>
                <el-dropdown
                    trigger="click"
                    placement="bottom"
                    class="filepicker"
                >
                    <el-button
                        plain
                        type="primary"
                        size="mini"
                        class="filepickerbutton"
                    >
                        {{ filename
                        }}<i class="el-icon-arrow-down el-icon--right"></i>
                    </el-button>
                    <el-dropdown-menu slot="dropdown">
                        <el-dropdown-item
                            v-for="(item, index) in files"
                            :key="index"
                            @click.native="pickFile(item)"
                            >{{ item }}</el-dropdown-item
                        >
                    </el-dropdown-menu>
                </el-dropdown>
                <el-button
                    type="primary"
                    class="checkbutton2"
                    @click="goGenerate"
                >
                    前往生成合约<i class="el-icon-right"></i>
                </el-button>
                <el-button
                    type="primary"
                    class="checkbutton"
                    @click="checkNow"
                    v-loading.fullscreen.lock="loading"
                >
                    立即验证<i class="el-icon-right"></i>
                </el-button>
                <prism-editor
                    class="my-editor"
                    v-model.trim="code"
                    :line-numbers="true"
                    :readonly="readonly"
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
    name: "dashboard",
    created() {
        this.code = this.$route.params.code;
    },
    components: {
        PrismEditor,
    },
    data() {
        return {
            prop1: [
                {
                    desc: "其他活动开始前，订单已创建",
                    prop:
                        "A[] (!Shipper.idle || !Carrier.idle || !Consignee.idle || !PreShipmentInspector.idle || !ExportPortOperator.idle || !ImportPortOperator.idle ) imply already_create",
                    num: 1,
                },
                {
                    desc: "其他活动开始前，参与方首先签订订单",
                    prop:
                        "A[] !Shipment.closed && (!Shipper.idle && !Shipper.create_called || !Carrier.idle && !Carrier.sign_called || !Consignee.idle && !Consignee.sign_called || !PreShipmentInspector.idle && !PreShipmentInspector.sign_called || !ExportPortOperator.idle && !ExportPortOperator.sign_called || !ImportPortOperator.idle && !ImportPortOperator.sign_called ) imply already_sign",
                    num: 2,
                },
                {
                    desc: "货物出发前，出发地相关活动已完成",
                    prop:
                        "A[] (Shipper.create_called || Shipper.cancel_called || Shipper.close_called || Carrier.sign_called || Consignee.sign_called || PreShipmentInspector.sign_called || PreShipmentInspector.inspect_called || ExportPortOperator.sign_called || ExportPortOperator.exportShipment_called) imply !already_depart",
                    num: 3,
                },
                {
                    desc: "出发后，货物或者送达，或者灭失",
                    prop:
                        "Shipment.departed --> Shipment.lost || Shipment.arrived",
                    num: 4,
                },
                {
                    desc: "到达地相关活动开始前，货物已到达",
                    prop:
                        "A[] (Carrier.rearrange_called || Consignee.receiveShipment_called || ImportPortOperator.importShipment_called) imply already_arrive",
                    num: 5,
                },
                { desc: "订单最终将结束", prop: "A<> Shipment.closed", num: 6 },
            ],
            prop2: [
                {
                    desc: "参与方余额始终非负",
                    prop: "A[] (sum(i:int[1,6])balances[i]) >=0",
                    num: 7,
                },
                {
                    desc: "所有参与方净收入之和始终为0",
                    prop: "A[] (sum(i:int[0,6])net[i]) ==0",
                    num: 8,
                },
                {
                    desc: "参与方余额之和始终等于订单合约净收入",
                    prop: "A[] (sum(i:int[1,6])balances[i]) == net[0]",
                    num: 9,
                },
                {
                    desc: "订单结束后，参与方余额最终将被取出",
                    prop:
                        "Shipment.closed --> (forall(i:int[1,6])balances[i]==0)",
                    num: 10,
                },
            ],
            prop3: [
                {
                    desc: "合约正确地记录了延迟送达",
                    prop:
                        "A[] (is_delayed imply block_timestamp > arrive_date) && (block_timestamp > arrive_date && arrive_timeCLK==0 imply is_delayed)",
                    num: 11,
                },
                {
                    desc:
                        "延迟送达后，或者参与方要求赔偿，或者超过申请时限后订单关闭",
                    prop:
                        "is_delayed --> Shipment.claimed || Shipment.closed && arrive_timeCLK>compensation_valid",
                    num: 12,
                },
                {
                    desc: "合约正确地记录了货物灭失",
                    prop:
                        "A[] (is_lost imply already_reportLoss) && (already_reportLoss imply is_lost)",
                    num: 13,
                },
                {
                    desc:
                        "货物灭失后，或者参与方要求赔偿，或者超过申请时限后订单关闭",
                    prop:
                        "is_lost --> Shipment.claimed || Shipment.closed && block_timestamp>arrive_date+compensation_valid",
                    num: 14,
                },
                {
                    desc: "合约正确地记录了货物损坏",
                    prop: "A[]  already_reportDamage imply is_damaged",
                    num: 15,
                },
                {
                    desc:
                        "货物损坏后，或者参与方要求赔偿，或者超过申请时限后订单关闭",
                    prop:
                        "is_damaged --> Shipment.claimed || Shipment.closed && arrive_timeCLK>compensation_valid",
                    num: 16,
                },
            ],
            prop4: [
                {
                    desc:
                        "赔偿限额始终小于 835 SDR 或 2.5 SDR/kg，取其中较小者",
                    prop:
                        "A[] compensation_limit <835 and compensation_limit <2.5*weight",
                    num: 17,
                },
                {
                    desc: "实际支付赔偿额小于运费的 2.5 倍",
                    prop:
                        "A[] is_delayed && !is_damaged && !is_lost imply net[carrier]+balances[carrier]>=transportation_fee*(1-2.5)",
                    num: 18,
                },
                {
                    desc:
                        "实际支付赔偿额小于 835 SDR 或 2.5 SDR/kg，取其中较小者",
                    prop:
                        "A[] (is_damaged || is_lost) imply (net[carrier]+balances[carrier]>= transportation_fee-835 && net[carrier]+balances[carrier]>= transportation_fee-weight*2.5)",
                    num: 19,
                },
                {
                    desc: "收货方应在收到货物后 90 天内申请赔偿",
                    prop:
                        "A[] Consignee.claim_called imply receive_timeCLK<=90",
                    num: 20,
                },
                {
                    desc:
                        "收货方应在货物到达后 90 天内接受货物，否则承运人有权拍卖或转卖货物",
                    prop:
                        "A[] Carrier.rearrange_called imply arrive_timeCLK>90",
                    num: 21,
                },
            ],
            prop5: [
                {
                    desc:
                        "赔偿限额始终小于 666.67 SDR 或 2 SDR/kg，取其中较小者",
                    prop:
                        "A[] compensation_limit<666.67 and compensation_limit<2*weight",
                    num: 22,
                },
                {
                    desc: "实际支付赔偿额小于运费的 2 倍",
                    prop:
                        "A[] is_delayed && !is_damaged && !is_lost imply net[carrier]+balances[carrier]>=transportation_fee*(1-1)",
                    num: 23,
                },
                {
                    desc:
                        "实际支付赔偿额小于 666.67 SDR 或 2 SDR/kg，取其中较小者",
                    prop:
                        "A[] (is_damaged || is_lost) imply (net[carrier]+balances[carrier]>= transportation_fee-666.67 && net[carrier]+balances[carrier]>= transportation_fee-weight*2)",
                    num: 24,
                },
                {
                    desc: "收货方应在收到货物后 7 天内申请赔偿",
                    prop: "A[] Consignee.claim_called imply receive_timeCLK<=7",
                    num: 25,
                },
                {
                    desc:
                        "收货方应在货物到达后 60 天内接受货物，否则承运人有权拍卖或转卖货物",
                    prop:
                        "A[] Carrier.rearrange_called imply arrive_timeCLK>60",
                    num: 26,
                },
            ],
            files: [
                "输入自定义合约",
                "IoT",
                "LNG",
                "Medical",
                "NFT1",
                "NFT2",
                "PPE",
                "Recall",
                "ShipChain",
                "eth-shipment",
            ],

            filename: "请选择示例合约",
            code: "",
            checkList1: [],
            checkList2: [],
            checkList3: [],
            checkList4: [],
            checkList5: [],
            diyList: [],
            ifCheckAll1: false,
            ifCheckAll2: false,
            ifCheckAll3: false,
            ifCheckAll4: false,
            ifCheckAll5: false,
            isIndeterminate1: false,
            isIndeterminate2: false,
            isIndeterminate3: false,
            isIndeterminate4: false,
            isIndeterminate5: false,
            loading: false,
            fileIndex: 0,
            readonly: false,
        };
    },
    methods: {
        highlighter(code) {
            return highlight(code, languages.sol, "sol");
        },
        addProp() {
            let list = {
                desc: "",
                prop: "",
            };
            this.diyList.push(list);
        },
        deleteProp(index, row) {
            this.diyList.splice(index, 1);
        },
        checkAll1(val) {
            this.checkList1 = val ? this.prop1 : [];
            this.isIndeterminate1 = false;
        },
        checkAll2(val) {
            this.checkList2 = val ? this.prop2 : [];
            this.isIndeterminate2 = false;
        },
        checkAll3(val) {
            this.checkList3 = val ? this.prop3 : [];
            this.isIndeterminate3 = false;
        },
        checkAll4(val) {
            this.checkList4 = val ? this.prop4 : [];
            this.isIndeterminate4 = false;
        },
        checkAll5(val) {
            this.checkList5 = val ? this.prop5 : [];
            this.isIndeterminate5 = false;
        },
        checked1(val) {
            let checkedCount = val.length;
            this.ifCheckAll1 = checkedCount == this.prop1.length;
            this.isIndeterminate1 =
                checkedCount > 0 && checkedCount < this.prop1.length;
        },
        checked2(val) {
            let checkedCount = val.length;
            this.ifCheckAll2 = checkedCount == this.prop2.length;
            this.isIndeterminate2 =
                checkedCount > 0 && checkedCount < this.prop2.length;
        },
        checked3(val) {
            let checkedCount = val.length;
            this.ifCheckAll3 = checkedCount == this.prop3.length;
            this.isIndeterminate3 =
                checkedCount > 0 && checkedCount < this.prop3.length;
        },
        checked4(val) {
            let checkedCount = val.length;
            this.ifCheckAll4 = checkedCount == this.prop4.length;
            this.isIndeterminate4 =
                checkedCount > 0 && checkedCount < this.prop4.length;
        },
        checked5(val) {
            let checkedCount = val.length;
            this.ifCheckAll5 = checkedCount == this.prop5.length;
            this.isIndeterminate5 =
                checkedCount > 0 && checkedCount < this.prop5.length;
        },
        readFile(name) {
            if (name == "输入自定义合约") {
                return "";
            }
            let xhr = new XMLHttpRequest();
            xhr.open("GET", "/static/" + name + ".txt", false);
            xhr.overrideMimeType("text/html;charset=utf-8");
            xhr.send(null);
            return xhr.responseText;
        },
        pickFile(filename) {
            if (filename == "输入自定义合约") {
                this.readonly = false;
            } else {
                this.readonly = true;
            }
            this.filename = filename;
            this.code = this.readFile(this.filename);
        },
        goGenerate() {
            this.$router.push("/generate");
        },
        checkNow() {
            // check if code is empty
            if (
                this.filename == "输入自定义合约" ||
                this.filename == "请选择示例合约"
            ) {
                this.$message.error("目前仅支持验证示例合约！");
                return;
            }
            if (this.code == "") {
                this.$message.error("合约代码不可为空！");
                return;
            }
            // check if diyList.prop is empty
            if (this.diyList.length > 0) {
                var flag = false;
                for (let i = 0; i < this.diyList.length; i++) {
                    console.log("prop", this.diyList[i].prop);
                    if (this.diyList[i].prop == "") {
                        flag = true;
                    }
                }
                if (flag == true) {
                    this.$message.error("添加的自定义性质不可为空！");
                    return;
                }
            }
            // check if property is empty
            if (
                this.diyList.length +
                    this.checkList1.length +
                    this.checkList2.length +
                    this.checkList3.length ==
                0
            ) {
                this.$message.error("请选择待检测性质");
                return;
            }
            this.loading = true;
            let propnums = [];
            let custom = [];
            for (let i = 0; i < this.checkList1.length; i++) {
                propnums.push(this.checkList1[i].num);
            }
            for (let i = 0; i < this.checkList2.length; i++) {
                propnums.push(this.checkList2[i].num);
            }
            for (let i = 0; i < this.checkList3.length; i++) {
                propnums.push(this.checkList3[i].num);
            }
            for (let i = 0; i < this.checkList4.length; i++) {
                propnums.push(this.checkList4[i].num);
            }
            for (let i = 0; i < this.checkList5.length; i++) {
                propnums.push(this.checkList5[i].num);
            }
            for (let i = 0; i < this.diyList.length; i++) {
                custom.push(this.diyList[i].prop);
            }
            let params = {
                src: this.code,
                property: propnums,
                custom: custom,
                filePicked: this.filename,
            };

            this.$router.push({
                name: "result",
                params: {
                    filename: this.filename,
                    checkList1: this.checkList1,
                    checkList2: this.checkList2,
                    checkList3: this.checkList3,
                    checkList4: this.checkList4,
                    checkList5: this.checkList5,
                    diyList: this.diyList,
                },
            });
            this.loading = false;
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
    height: 1300px;
    border-radius: 5px;
    background-color: white;
    position: absolute;
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
.checkbox {
    font-size: 20px;
    left: 40px;
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
.classes {
    font-size: 14px;
    font-weight: bold;
    color: #818998;
    left: 25px;
    height: 15px;
    position: relative;
    line-height: 0px;
}
.checkbutton {
    font-size: 20px;
    right: 25px;
    position: absolute;
    font-weight: bold;
    top: 15px;
}
.checkbutton2 {
    font-size: 20px;
    left: 880px;
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
.checkAll {
    position: relative;
    left: 25px;
}
.filepicker {
    position: absolute;
    top: 20px;
    left: 635px;
}
.filepickerbutton {
    font-size: 18px;
    font-weight: bold;
}
</style>
