import { Component, OnInit } from '@angular/core';
import { MenuItem } from 'primeng/components/common/menuitem';

@Component({
  selector: 'app-menu',
  templateUrl: './menu.component.html',
  styleUrls: ['./menu.component.css']
})
export class MenuComponent implements OnInit {
  public items: MenuItem[] = [];
  constructor() { }

  ngOnInit() {
    this.items.push(
      { routerLink: '/publisher', label: 'Case Editrici', icon: 'fa fa-address-book' },
      { routerLink: '/wholesaler', label: 'Distributori', icon: 'fa fa-map-signs' },
      { routerLink: '/book', label: 'Libri', icon: 'fa fa-book' },
      { routerLink: '/school', label: 'Scuole', icon: 'fa fa-university' },
      { routerLink: '/class', label: 'Classi', icon: 'fa fa-cubes' },
      { routerLink: '/student', label: 'Studenti', icon: 'fa fa-users' },
      { routerLink: '/booking', label: 'Prenotazioni', icon: 'fa fa-list-alt' },
      { routerLink: '/order', label: 'Ordini', icon: 'fa fa-list-alt' },
      { routerLink: '/remind', label: 'Solleciti', icon: 'fa fa-question' },
      { routerLink: '/student-detail', label: 'Studenti per Classe', icon: 'fa fa-users' }
    );
  }

}
