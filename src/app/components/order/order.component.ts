import { Component, OnInit } from '@angular/core';
import { Router } from '@angular/router';
import { MenuItem } from 'primeng/api';
@Component({
  selector: 'app-order',
  templateUrl: './order.component.html',
  styleUrls: ['./order.component.css']
})
export class OrderComponent implements OnInit {
  router: Router;
  items: MenuItem[] = [];
  constructor() {

  }

  ngOnInit() {
    this.items.push(
      { routerLink: '/order/list', label: 'Ordini' },
      { routerLink: '/order/new', label: 'Nuovo Ordine', icon: 'fa fa-map-signs' },
      { routerLink: '/order/arrival', label: 'Registro arrivi' },
      { routerLink: '/order/deliver', label: 'Consegna libri' }
    );
  }


}
