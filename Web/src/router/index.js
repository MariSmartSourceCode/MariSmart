import Vue from 'vue'
import Router from 'vue-router'
// in development env not use Lazy Loading,because Lazy Loading too many pages will cause webpack hot update too slow.so only in production use Lazy Loading
/* layout */
import Layout from '../views/layout/Layout'

const _import = require('./_import_' + process.env.NODE_ENV)
Vue.use(Router)
export const constantRouterMap = [
  {path: '/login', component: _import('login/index'), hidden: true},
  {path: '/404', component: _import('404'), hidden: true},
  {
    path: '/',
    component: Layout,
    redirect: '/dashboard',
    name: 'dashboard',
    hidden: true,
    children: [
      {path: 'dashboard', component: _import('dashboard/index')},
      {
        path: '/result', 
        component: _import('result/index'), 
        name: 'result',
        hidden: true
      },
      {path: '/generate', component: _import('generate/index'), hidden: true}
    ]
  },
  {
    path: '/en',
    component: Layout,
    redirect: '/dashboard-en',
    name: 'dashboard-en',
    hidden: true,
    children: [
      {path: '/dashboard-en', component: _import('dashboard/index-en')},
      {
        path: '/result-en', 
        component: _import('result/index-en'), 
        name: 'result-en',
        hidden: true
      },
      {path: '/generate-en', name:'generate-en',component: _import('generate/index-en'), hidden: true}
    ]
  },
]
export default new Router({
  // mode: 'history', //后端支持可开
  scrollBehavior: () => ({y: 0}),
  routes: constantRouterMap
})
export const asyncRouterMap = [
  {path: '*', redirect: '/404', hidden: true}
]
